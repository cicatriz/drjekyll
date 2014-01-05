drjekyll
========

Jekyll + Papers as a research knowledge base

- Jekyll: http://jekyllrb.com
- Papers: http://www.papersapp.com/

### Example

http://research-wiki.herokuapp.com/

### Getting started

1. Fork this repo
2. Run `jekyll serve` in the directory
3. Open http://localhost:4000 in your browser

### Exporting bibliography (DO THIS FIRST)

1. In Papers, File > Export... > BibTeX Library
2. Save as `lib.bib` in the root directory with the default settings

Unfortunately you'll have to do this any time there are updates to your
Papers bibliography. You can see a citation entry in the path
`/ref/citekey.html` replacing "citekey" with the Papers 2 citekey. 

### Adding posts

See http://jekyllrb.com for information about using Jekyll. Within your
posts, you can create a link to a citation using `{% cite citekey %}`.
Replacing "citekey" with the Papers citekey (which can be inserting
using Paper's ctrl, ctrl shortcut if enabled).

### Adding highlights

1. In Papers, File > Export... > Notes
2. Save as `highlights.txt` in the root directory with the "Plain text"
   format

### Adding notes

Create a file `notes/citekey.md` based on the Papers citekey.
