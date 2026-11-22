# frozen_string_literal: true

require "date"
require "find"
require "pathname"
require "yaml"

module Harwirz
  class BundleStaticFile < Jekyll::StaticFile
    def initialize(site, base, dir, name, post, asset_rel_path)
      super(site, base, dir, name)
      @post = post
      @asset_rel_path = asset_rel_path
    end

    def destination(dest)
      File.join(File.dirname(@post.destination(dest)), @asset_rel_path)
    end
  end

  module BundleAwarePostReader
    def read_content(dir, magic_dir, matcher)
      docs = super
      return docs unless magic_dir == "_posts"

      posts_root = @site.in_source_dir(File.join(dir, magic_dir))
      posts_pathname = Pathname.new(posts_root)

      docs.reject do |doc|
        rel = Pathname.new(doc.path).relative_path_from(posts_pathname).to_s
        top_dir = rel.split("/").first
        next false unless rel.include?("/") && top_dir

        File.file?(File.join(posts_root, top_dir, "index.md"))
      end
    end
  end

  module PostBundles
    BUNDLE_DIR_REGEX = /\A(\d{4}-\d{2}-\d{2})-(.+)\z/.freeze

    def self.register(site)
      posts_root = File.join(site.source, "_posts")
      return unless Dir.exist?(posts_root)

      existing_paths = site.posts.docs.map(&:path).each_with_object({}) { |p, h| h[p] = true }
      added = false

      Dir.children(posts_root).sort.each do |entry|
        next if entry.start_with?(".")

        bundle_dir = File.join(posts_root, entry)
        next unless File.directory?(bundle_dir)

        index_path = File.join(bundle_dir, "index.md")
        next unless File.file?(index_path)
        next if existing_paths[index_path]

        doc = build_document(site, index_path, entry)
        next unless site.publisher.publish?(doc)

        site.posts.docs << doc
        existing_paths[index_path] = true
        added = true

        attach_bundle_assets(site, bundle_dir, entry, doc)
      end

      site.posts.docs.sort! if added
    end

    def self.build_document(site, index_path, bundle_name)
      raw_front_matter = read_front_matter_keys(index_path)

      doc = Jekyll::Document.new(index_path, site: site, collection: site.posts)
      doc.read

      match = BUNDLE_DIR_REGEX.match(bundle_name)
      dir_date = match ? match[1] : nil
      dir_slug = match ? match[2] : bundle_name

      doc.data["layout"] = "post" if blank?(doc.data["layout"])
      doc.data["slug"] = dir_slug if !raw_front_matter.include?("slug") && (blank?(doc.data["slug"]) || doc.data["slug"] == "index")

      if !raw_front_matter.include?("title") && (blank?(doc.data["title"]) || doc.data["title"] == "Index")
        doc.data["title"] = dir_slug
      end

      if !raw_front_matter.include?("date") && dir_date
        doc.data["date"] = Jekyll::Utils.parse_date(
          "#{dir_date} 00:00:00",
          "Bundle directory '#{bundle_name}' has an invalid date prefix."
        )
      end

      unless raw_front_matter.include?("permalink")
        doc.data["permalink"] = "/posts/#{bundle_name}/"
      end

      doc.instance_variable_set(:@url, nil)
      doc
    end

    def self.attach_bundle_assets(site, bundle_dir, bundle_name, doc)
      bundle_pathname = Pathname.new(bundle_dir)
      asset_paths = []

      Find.find(bundle_dir) do |abs_path|
        next if abs_path == bundle_dir

        base = File.basename(abs_path)
        if base.start_with?(".")
          Find.prune if File.directory?(abs_path)
          next
        end

        next unless File.file?(abs_path)

        rel_path = Pathname.new(abs_path).relative_path_from(bundle_pathname).to_s
        next if rel_path == "index.md"
        next if rel_path.end_with?("~")

        asset_paths << rel_path
      end

      asset_paths.sort.each do |rel_path|
        rel_dir = File.dirname(rel_path)
        source_dir = rel_dir == "." ? File.join("_posts", bundle_name) : File.join("_posts", bundle_name, rel_dir)
        file_name = File.basename(rel_path)

        site.static_files << BundleStaticFile.new(
          site,
          site.source,
          source_dir,
          file_name,
          doc,
          rel_path
        )
      end
    end

    def self.read_front_matter_keys(path)
      content = File.read(path, encoding: "UTF-8")
      return [] unless content.start_with?("---\n", "---\r\n")

      match = content.match(/\A---\r?\n(.*?)\r?\n---(?:\r?\n|\z)/m)
      return [] unless match

      data = YAML.safe_load(match[1], permitted_classes: [Time, Date])
      data.is_a?(Hash) ? data.keys.map(&:to_s) : []
    rescue StandardError
      []
    end

    def self.blank?(value)
      value.nil? || value.to_s.strip.empty?
    end
  end
end

Jekyll::PostReader.prepend(Harwirz::BundleAwarePostReader)

Jekyll::Hooks.register :site, :post_read do |site|
  Harwirz::PostBundles.register(site)
end
