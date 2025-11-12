# VIM Cheatsheets

## VIM Motions

Команды для перемещения курсора

* `gg` - Start of buffer
* `G` - End of buffer
* `0` - Start of string
* `$` - End of string
* `w` - Go forward one word
* `b` - Go back one word
* `h|j||k|l` - left|down|up|right
* `)` - Go forwards one sentence
* `(` - Go backards one sentence 

Команды вставки

- `i` - Вставить в позицию курсора.
- `I` - Вставить начало текущей строки.
- `a` - append text after the cursor
- `A` - append text ta the end of current line
- `o` - open a new line bellow the position
- `O` - open a new line above thr current line
 
- `c` - Изменить диапазон (example: c2w - удалить 2 слова и перейти в режим вставки).
- `d` - Удалить диапазон (example: d3w - удалить 3 слова).
- `g~` - Изменить регистр.
- `gu` - Строчный регистр.
- `gU` - Верхний регистр.

Можно использовать модификатор количества, например `d3w` удалит 3 слова. 
-------------------------------------------------------------------------
