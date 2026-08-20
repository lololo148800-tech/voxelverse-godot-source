# Патч: хотбар в survival должен брать блоки из инвентаря, а не показывать фиксированный список

Файл: `core/voxel_world.gd` (в репозитории 5279 строк — я не вижу его
целиком через GitHub веб-интерфейс, поэтому это не полный файл-замена,
а точечная правка. Найди эти места по названиям переменных/функций и
поменяй руками или отдай этот файл ИИ с просьбой применить именно
в voxel_world.gd).

## Что сейчас (баг)

```gdscript
var hotbar: Array[int] = [GRASS, DIRT, STONE, WOOD, SAND, SNOW, CRYSTAL, GLOW]
var inventory: Dictionary = {GRASS: 32, DIRT: 64, STONE: 24, ...}
```

Хотбар — фиксированный список, не зависящий от режима игры и реального
инвентаря. Поэтому в survival всё равно доступен весь список блоков.

## Что нужно вставить

Добавь новую функцию рядом с объявлением `hotbar`:

```gdscript
func get_hotbar_items() -> Array[int]:
    if creative_mode:
        return hotbar
    var owned: Array[int] = []
    for item_id in hotbar:
        if int(inventory.get(item_id, 0)) > 0:
            owned.append(item_id)
    return owned
```

## Где заменить использование

Найди в файле место (скорее всего в обработчике клавиш 1-8 для выбора
слота), где написано что-то вроде:

```gdscript
selected_block = hotbar[event.keycode - KEY_1]
```

Замени на:

```gdscript
if event.keycode >= KEY_1 and event.keycode <= KEY_8:
    var available := get_hotbar_items()
    var slot_index := event.keycode - KEY_1
    if slot_index < available.size():
        selected_block = available[slot_index]
```

## И там, где ставится блок (функция типа `_place_target()` / `place_block()`)

Перед фактической установкой добавь списание с инвентаря, если не креатив:

```gdscript
if not creative_mode:
    var count := int(inventory.get(selected_block, 0))
    if count <= 0:
        return  # блока нет — ставить нечего
    inventory[selected_block] = count - 1
```

## И там, где ломается блок (функция типа `break_block()`)

Добавь начисление в инвентарь:

```gdscript
if not creative_mode:
    inventory[block_type] = int(inventory.get(block_type, 0)) + 1
```

---

Если mobile_overlay.gd рисует хотбар отдельно от voxel_world.gd — там
тоже нужно вызывать `voxel_world.get_hotbar_items()` вместо любого
захардкоженного списка при отрисовке иконок слотов.
