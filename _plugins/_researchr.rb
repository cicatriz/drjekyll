module Jekyll
  require 'bibtex'
  require 'zlib'

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

      hl_file = File.join(base, 'highlights', filename)
      
      if File.exists?(hl_file)
        hl_page = Page.new(site, base, 'highlights', filename)
        hl_page.render(site.layouts, site.site_payload)
        self.data['highlights'] = hl_page.content
      end 

      self.data = self.data.merge(ref)
    end
  end

  class HighlightsGenerator < Generator
    safe true

    def generate(site)
      dir = site.config['highlights_dir'] || 'highlights'
      hl_file = site.config['highlights_file'] || 'highlights.txt'
      cur_file = nil
      
      File.readlines(hl_file).each do |line|
        if line =~ /^(.*?) \((\d\d\d\d)\)\. ([^.]*)\.(.*?)(doi:(.*))?$/
          authors = $1
          year = $2
          title = $3
          doi = $6

          # https://github.com/cparnot/universal-citekey-js/blob/master/universal-citekey.js
          if doi # gen hash from doi
            crc = Zlib::crc32(doi)
            first = 'b'.ord + ((crc % (10*26)) / 26).floor
            second = 'a'.ord + crc % 26
            hash = "#{first.chr}#{second.chr}"
          else # gen hash from title 
            excluded_characters = "±˙˜´‘’‛“”‟·•!¿¡#∞£¥$%‰&˝¨ˆ¯˘¸˛^~√∫*§◊¬¶†‡≤≥÷:ªº\"\'©®™"
            #replaced_characters = "°˚+-–—_…,.;ı(){}‹›<>«=≈?|/\\"
            replaced_characters = "-" # something weird happening with above set

            crc_title = title.downcase.tr(replaced_characters, ' ').tr(excluded_characters, '').gsub(/\s+/,' ')
            crc = Zlib::crc32(crc_title)
            first = 't'.ord + ((crc % (4*26)) / 26)
            second = 'a'.ord + crc % 26
            hash = "#{first.chr}#{second.chr}"
          end

          citekey = "#{authors.split(',')[0]}:#{year}#{hash}"

          puts "found highlights for citekey #{citekey}"

          name = "#{citekey}.md"
          cur_file = File.open(File.join(dir, name), 'w')
          cur_file.write("")
        else
          if cur_file
            cur_file.puts line
          end
        end
      end
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
