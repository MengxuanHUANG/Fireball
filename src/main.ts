import {vec2, vec3, vec4, mat4} from 'gl-matrix';
const Stats = require('stats-js');
import * as DAT from 'dat.gui';
import Square from './geometry/Square';
import Icosphere from './geometry/Icosphere';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';

// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const controls = {
  tesselations: 5,
  'Load Scene': loadScene, // A function pointer, essentially
  speed: 1 
};

let icosphere: Icosphere;
let square: Square;
let time: number = 0;

function loadScene() {
  icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 3, controls.tesselations);
  icosphere.create();

  square = new Square(vec3.fromValues(0, 0, 0));
  square.create();
  // time = 0;
}

function main() {

  // Initial display for framerate
  const stats = Stats();
  stats.setMode(0);
  stats.domElement.style.position = 'absolute';
  stats.domElement.style.left = '0px';
  stats.domElement.style.top = '0px';
  document.body.appendChild(stats.domElement);

  // Add controls to the gui
  const gui = new DAT.GUI();
  gui.add(controls, 'tesselations', 0, 8).step(1);
  gui.add(controls, 'Load Scene');
  gui.add(controls, 'speed', 1, 8).step(0.1);

  window.addEventListener('keypress', function (e) {
    // console.log(e.key);
    switch(e.key) {
      // Use this if you wish
    }
  }, false);

  window.addEventListener('keyup', function (e) {
    switch(e.key) {
      // Use this if you wish
    }
  }, false);

  // get canvas and webgl context
  const canvas = <HTMLCanvasElement> document.getElementById('canvas');
  const gl = <WebGL2RenderingContext> canvas.getContext('webgl2');
  if (!gl) {
    alert('WebGL 2 not supported!');
  }
  // `setGL` is a function imported above which sets the value of `gl` in the `globals.ts` module.
  // Later, we can import `gl` from `globals.ts` to access it
  setGL(gl);

  // Initial call to load scene
  loadScene();

  const camera = new Camera(vec3.fromValues(0, 0, -10), vec3.fromValues(0, 0, 0));

  const renderer = new OpenGLRenderer(canvas);
  renderer.setClearColor(164.0 / 255.0, 233.0 / 255.0, 1.0, 1);
  gl.enable(gl.DEPTH_TEST);

  const flat = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/flat-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/flat-frag.glsl')),
  ]);
  const sphere_shader = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/noise-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/lambert-frag.glsl')),
  ]);
  const fireball_shader = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/fireball-noise-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/lambert-frag.glsl')),
  ]);
  function processKeyPresses() {
    // Use this if you wish
  }

  // This function will be called every frame
  function tick() {
    camera.update();
    let viewProj = mat4.create();
    mat4.multiply(viewProj, camera.projectionMatrix, camera.viewMatrix);

    stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    renderer.clear();
    processKeyPresses();
    
    var model = mat4.create();
    var modelinvtr: mat4 = mat4.create();
    mat4.identity(model);
    mat4.identity(modelinvtr);

    mat4.translate(model, model, vec3.fromValues(0, 0, 10));

    mat4.transpose(modelinvtr, model);
    mat4.invert(modelinvtr, modelinvtr);
    
    let center = vec4.fromValues(0, 0, 0, 1);
    //vec4.transformMat4(center, center, viewProj);

    flat.setUniformFloat2("u_Dimensions", vec2.fromValues(window.innerWidth, window.innerHeight));
    flat.setUniformFloat4("u_Fireball_Pos", center);
    flat.setUniformMat4("u_Model", model);
    flat.setUniformMat4("u_ViewProj", viewProj);
    flat.setUniformFloat("u_Raius", icosphere.radius);

    let right = vec3.create();
    camera.controls.eye, camera.controls.center, camera.controls.up
    vec3.cross(right, vec3.subtract(vec3.create(), camera.controls.center, camera.controls.eye), camera.controls.up);
    vec3.normalize(right, right);
    flat.setUniformFloat3("u_Right", right);
    renderer.render(camera, flat, [
      square,
    ], controls.speed * time);

    gl.disable(gl.DEPTH_TEST);

    gl.enable(gl.BLEND);
    gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);

    fireball_shader.setUniformMat4("u_Model", model);
    fireball_shader.setUniformMat4("u_ModelInvTr", modelinvtr);
    fireball_shader.setUniformFloat4("u_LightPos", vec4.fromValues(5, 5, 3, 1));
    fireball_shader.setUniformMat4("u_ViewProj", viewProj);
    renderer.render(camera, fireball_shader, [
      icosphere,
    ], controls.speed * time);

    
    mat4.identity(model);
    mat4.identity(modelinvtr);
    mat4.scale(model, model, vec3.fromValues(0.25, 0.25, 0.25));
    mat4.translate(model, model, vec3.fromValues(-5, 0, 0));
    mat4.transpose(modelinvtr, model);
    mat4.invert(modelinvtr, modelinvtr);
    //sphere_shader.setUniformMat4("u_Model", model);
    sphere_shader.setUniformMat4("u_ModelInvTr", modelinvtr);
    sphere_shader.setUniformFloat4("u_LightPos", vec4.fromValues(5, 5, 3, 1));
    //renderer.render(camera, sphere_shader, [
    //  icosphere,
    //], time);

    time++;
    stats.end();

    // Tell the browser to call `tick` again whenever it renders a new frame
    requestAnimationFrame(tick);
  }

  window.addEventListener('resize', function() {
    renderer.setSize(window.innerWidth, window.innerHeight);
    camera.setAspectRatio(window.innerWidth / window.innerHeight);
    camera.updateProjectionMatrix();
    flat.setDimensions(window.innerWidth, window.innerHeight);
  }, false);

  renderer.setSize(window.innerWidth, window.innerHeight);
  camera.setAspectRatio(window.innerWidth / window.innerHeight);
  camera.updateProjectionMatrix();
  flat.setDimensions(window.innerWidth, window.innerHeight);

  // Start the render loop
  tick();
}

main();
