# 🏇 Carrera de Caballos — Proyecto Godot 4

## Cómo abrir el proyecto

1. Abre **Godot 4.x** (descárgalo en https://godotengine.org si no lo tienes)
2. En la pantalla principal haz clic en **"Importar"**
3. Navega hasta esta carpeta `horse_racing/`
4. Selecciona el archivo `project.godot` y haz clic en **Abrir**
5. Presiona **F5** o el botón ▶ para jugar

## Cómo se juega

1. Elige uno de los **5 caballos** haciendo clic en su botón
2. Escribe la cantidad que quieres apostar (mínimo $10)
3. Presiona **¡CORRER!**
4. Observa la carrera en tiempo real
5. Si tu caballo gana, ¡cobras tu apuesta × la cuota!

## Caballos y cuotas

| Caballo    | Cuota | Color    |
|------------|-------|----------|
| Relámpago  | ×2.5  | 🔴 Rojo  |
| Tornado    | ×3.0  | 🔵 Azul  |
| Ceniza     | ×4.0  | ⚫ Gris  |
| Dorado     | ×2.0  | 🟡 Dorado|
| Nocturno   | ×5.0  | 🟣 Morado|

## Estructura del proyecto

```
horse_racing/
├── project.godot       ← Configuración del proyecto
├── icon.svg            ← Ícono del juego
├── scenes/
│   └── Main.tscn       ← Escena principal
└── scripts/
	└── Main.gd         ← Lógica del juego (GDScript)
```
