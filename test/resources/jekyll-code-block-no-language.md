```
#! /usr/bin/env python3

import tika
from tika import parser

fileIn = "berk011veel01_01.epub"
fileOut = "berk011veel01_01.txt"

parsed = parser.from_file(fileIn)
content = parsed["content"]

with open(fileOut, 'w', encoding='utf-8') as fout:
    fout.write(content)
```