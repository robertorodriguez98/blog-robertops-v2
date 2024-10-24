#!/bin/bash

npx pnpm build
rsync -azP dist/* calcetines@nodriza.robertops.com:/home/calcetines/blog/

