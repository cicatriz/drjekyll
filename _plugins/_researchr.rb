module Jekyll
  require 'bibtex'

  class CiteTag < Liquid::Tag
    def initialize(tag_name, citekey, tokens)
      super
      @citekey = citekey.strip
    end

    def namify(names) # TODO move
      return names[0] if names.size == 1
      return names[0] + ' et al.' if names.size > 3
      names[0..-2].join(', ') + ' &amp; ' + names[-1].to_s
    end

    def render(context)
      file = 'lib.bib' # TODO or from site config
      bib = BibTeX.open("./#{file}")
      ref = bib[@citekey]

      ax = []
      ref.author.each { |a| ax << a.last }

      "<a href=\"/ref/#{@citekey}.html\">#{namify(ax)}, #{ref.year}</a>"
    end
  end

  class RefPage < Page
    def initialize(site, base, dir, ref)
      @site = site
      @base = base
      @dir = dir
      @name = "#{ref['citekey']}.html"
      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), 'reference_page.html')

      filename = "#{ref['citekey']}.md"
      notes_file = File.join(base, 'notes', filename)

      if File.exists?(notes_file)
        notes_page = Page.new(site, base, 'notes', filename)
        notes_page.render(site.layouts, site.site_payload)
        self.data['notes'] = notes_page.content
      end

      self.data = self.data.merge(ref)
    end
  end

  class ReferenceGenerator < Generator
    safe true

    def generate(site)
      if site.layouts.key? 'reference_page'
        dir = site.config['ref_dir'] || 'ref'
        file = site.config['bib_file'] || 'lib.bib'
        bib = BibTeX.open("./#{file}")

        bib.each do |ref|
          refhash = Hash.new
          refhash['citekey'] = ref.key.to_s
          refhash['type'] = ref.type.to_s
          ref.each do |k,v|
            refhash[k.to_s] = v.to_s.gsub /^{(.*)}$/, '\1'
          end
          
          write_ref_page(site, dir, refhash)
        end
      end
    end

    def write_ref_page(site, dir, ref)
      page = RefPage.new(site, site.source, dir, ref)
      page.render(site.layouts, site.site_payload)
      page.write(site.dest)
      site.pages << page
    end
  end
end

Liquid::Template.register_tag('cite', Jekyll::CiteTag)
