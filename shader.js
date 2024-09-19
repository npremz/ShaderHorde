// 1. Initialisation de la scène
const scene = new THREE.Scene();

// 2. Caméra
const camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 1000);
camera.position.z = 1;

// 3. Renderer
const renderer = new THREE.WebGLRenderer();
renderer.setSize(window.innerWidth, window.innerHeight);
document.body.appendChild(renderer.domElement);

// 4. Uniformes (pour passer iTime et iResolution)
const uniforms = {
	iTime: { value: 0.0 },
	iResolution: { value: new THREE.Vector2(window.innerWidth, window.innerHeight) },
	iMouse: { value: new THREE.Vector2(0.0, 0.0) }  // Position de la souris initialisée à zéro
};

window.addEventListener('mousemove', (event) => {
	// Normaliser les coordonnées de la souris entre 0.0 et 1.0
	uniforms.iMouse.value.x = event.clientX / window.innerWidth;
	uniforms.iMouse.value.y = 1.0 - event.clientY / window.innerHeight;  // Inverser Y pour correspondre au système de coordonnées du shader
});

// 5. Charger le fichier fragment shader
fetch('fragmentShader.glsl')
	.then(response => response.text())
	.then(fragmentShaderCode => {
		// Créer le matériau avec le fragment shader chargé
		const material = new THREE.ShaderMaterial({
			uniforms: uniforms,
			vertexShader: `
				void main() {
					gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
				}
			`,
			fragmentShader: fragmentShaderCode
		});

		// 6. Géométrie et application du matériau
		const geometry = new THREE.PlaneGeometry(8, 4);
		const plane = new THREE.Mesh(geometry, material);
		scene.add(plane);

		// 7. Animation
		function animate(time) {
			requestAnimationFrame(animate);

			// Mettre à jour l'uniforme iTime avec le temps écoulé
			uniforms.iTime.value = time * 0.001;  // Convertir en secondes

			// Rendu de la scène
			renderer.render(scene, camera);
		}

		animate();
	})
	.catch(err => console.error("Erreur lors du chargement du fragment shader : ", err));
