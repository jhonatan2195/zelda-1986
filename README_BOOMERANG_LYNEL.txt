PROYECTO ZELDA-LUNES-ENEMY — LYNEL CON BUMERÁN

Base: proyecto entregado por el usuario.
Motor configurado: Godot 4.7 / GL Compatibility.

Cambios realizados:
- El Lynel utiliza res://bomerang.tscn como proyectil.
- El bumerán sale hacia la posición actual del jugador.
- El bumerán gira mientras vuela.
- Tiene alcance máximo y luego regresa al Lynel que lo lanzó.
- El jugador recibe daño una sola vez por lanzamiento.
- El bumerán también retorna si encuentra una colisión del mundo.
- Se eliminaron dos instancias estáticas de bumerán que estaban dentro de lynel.tscn.
- Se corrigió el descuento doble de vida en lynel.gd.
- El Lynel rojo queda configurado para hacer daño aumentado mediante IS_RED_VARIANT.

Para abrir:
1. Extrae el ZIP completo.
2. Abre la carpeta extraída desde Godot.
3. Selecciona project.godot.
4. Ejecuta la escena principal.

Nota de verificación:
La estructura, referencias res:// y archivos críticos fueron comprobados estáticamente. Este entorno no tiene el ejecutable de Godot instalado, por lo que no se pudo ejecutar el proyecto dentro de este entorno.


Ajuste de visibilidad de proyectiles:
- Lanza de Molblin azul: 58 px/s; distancia ampliada para mantenerla visible.
- Lanza de Molblin roja: 68 px/s.
- Bumerán de Lynel: salida 22 px/s, regreso 24 px/s, alcance 105 px y rotación 100°/s.
- Bumerán restaurado a escala 1.0 para que sus 5x8 píxeles se vean correctamente.
- El lanzamiento a distancia del Lynel tiene 0.65 s de preparación para que se perciba antes de salir.
