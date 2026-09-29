PROYECTO ZELDA-LUNES-ENEMY — LYNEL CON BUMERÁN

Base: proyecto entregado por el usuario.
Motor configurado: Godot 4.7 / GL Compatibility.

===================================================================
1) CAMBIOS DE VERSIONES ANTERIORES (ya incluidos en este ZIP)
===================================================================
- El Lynel utiliza res://bomerang.tscn como proyectil.
- El bumerán sale hacia la posición actual del jugador y regresa al Lynel
  que lo lanzó (alcance máximo y luego retorno).
- El jugador recibe daño una sola vez por lanzamiento.
- El bumerán también retorna si encuentra una colisión del mundo.
- Se eliminaron dos instancias estáticas de bumerán que estaban dentro de
  lynel.tscn.
- Se corrigió el descuento doble de vida en lynel.gd.
- El Lynel rojo queda configurado para hacer daño aumentado mediante
  IS_RED_VARIANT.
- Tamaño del bumerán ajustado: Sprite2D a escala (1.25, 1.25) → 6.25x10 px
  en pantalla (el Lynel se ve a 36x16 px), para que sea visible pero más
  pequeño que el Lynel.
- Se quitó la estela (Line2D) que se había probado para reforzar la
  dirección del vuelo: por pedido explícito solo se ve el sprite girando.
- Velocidad del bumerán reducida en varias iteraciones hasta:
    OUT_SPEED:      8.0
    RETURN_SPEED:   10.0
    ROTATION_SPEED: 90.0  (giro más lento y legible)

===================================================================
2) CAMBIOS DE ESTA CORRECCIÓN
===================================================================

A) Los Octorok habían desaparecido — RECUPERADOS
   Causa: los archivos octorok.gd, octorok.tscn, octorok_blue.gd y
   octorok_blue.tscn, además de lynel_spawner.gd, ya no estaban incluidos
   en el ZIP que se venía corrigiendo (solo quedaban las imágenes en
   AssetsEX/02_Overworld_Enemies). Sin esos archivos, Godot no podía
   instanciarlos y por eso no aparecían en el juego.

   Corrección:
   - Se recuperaron esos 6 archivos desde el proyecto original.
   - Se restauraron en scene_game.tscn los ext_resource que faltaban
     (octorok.tscn, octorok_blue.tscn, lynel_spawner.gd).
   - Se volvieron a agregar los nodos, en las mismas posiciones que tenían
     en el proyecto original:
       Octorok, Octorok2, Octorok3, Octorok4  (Octorok rojo)
       OctorokBlue, OctorokBlue2               (Octorok azul)
       LynelSpawner                            (nodo con lynel_spawner.gd)
   - De paso, se corrigió en lynel_spawner.gd la ruta
     preload("res://Lynel.tscn") (con mayúscula) por
     preload("res://lynel.tscn"), el nombre real del archivo; en sistemas
     sensibles a mayúsculas/minúsculas (Linux, exportación Web) esa ruta
     mal escrita habría impedido cargar el script.

B) El bumerán recorría muy poca distancia — CORREGIDO (dos ajustes)
   1er ajuste: se aumentó MAX_DISTANCE en bomerang.gd de 120.0 a 260.0, un
   poco por encima del alcance máximo de ataque a distancia del Lynel
   (RANGED_ATTACK_RANGE = 250.0).
   2do ajuste (por pedido explícito, seguía viéndose corto): se aumentó de
   nuevo, de 260.0 a 400.0, para que el vuelo de ida sea claramente más
   largo y se note mejor el lanzamiento del Lynel.

Archivos modificados/recuperados en esta corrección:
- bomerang.gd            (MAX_DISTANCE 120.0 -> 260.0 -> 400.0)
- lynel_spawner.gd       (recuperado + ruta preload corregida)
- octorok.gd, octorok.gd.uid, octorok.tscn             (recuperados)
- octorok_blue.gd, octorok_blue.gd.uid, octorok_blue.tscn (recuperados)
- lynel_spawner.gd.uid   (recuperado)
- scene_game.tscn        (ext_resource y nodos de Octorok/Spawner restaurados)

===================================================================
Para abrir
===================================================================
1. Extrae el ZIP completo.
2. Abre la carpeta extraída desde Godot 4.7.
3. Selecciona project.godot.
4. Ejecuta la escena principal (scene_game.tscn).

===================================================================
Nota de verificación
===================================================================
La estructura, las referencias res:///ext_resource y la sintaxis de los
archivos .gd/.tscn modificados se revisaron manualmente con cuidado,
comparando contra el proyecto original para restaurar exactamente los
mismos UID y posiciones. Este entorno no tiene el ejecutable de Godot
instalado, por lo que no se pudo abrir ni ejecutar el proyecto aquí;
se recomienda abrirlo en Godot 4.7 y confirmar que los Octorok aparecen
y que el bumerán llega bien hasta el jugador antes de entregarlo.

===================================================================
3) CORRECCION: EL BUMERAN AHORA VUELA HACIA EL JUGADOR
===================================================================
Causa del problema:
- start_position se guardaba en _ready(), ANTES de que el Lynel colocara el
  bumeran en su posicion; valia (0,0) y en el primer frame el bumeran creia
  haber recorrido 400 px y volvia de inmediato al Lynel.
- OUT_SPEED era 8 px/s (casi quieto) y se dibujaba debajo del jugador
  (z 20 contra 100).

Cambios:
- bomerang.gd: nuevo metodo launch(from, target_pos, owner, dmg). Vuela recto
  hacia la posicion del jugador, lo sobrepasa 50 px y regresa al Lynel.
  OUT_SPEED 150, RETURN_SPEED 170, giro 900 grados/seg.
- bomerang.tscn: z_index 200 (siempre por encima del jugador), escala 2x
  (10x16 px), sombra en el suelo (nodo Shadow) para dar efecto de aire,
  hitbox de radio 4.
- lynel.gd: _spawn_projectile() usa launch().
Nota: no se pudo ejecutar Godot en este entorno; probar en Godot 4.x.

4) TAMANO: el bumeran se redujo a escala 1.5 (7.5x12 px), mas pequeno que el
   Lynel (32x16 px). Sombra a 6 px y hitbox de radio 3.
