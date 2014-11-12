# encoding: UTF-8
module Paperclip
  class Watermark < Processor
    attr_accessor :current_geometry, :target_geometry, :format

    def initialize(file, options = {}, attachment = nil)
      super
      geometry         = options[:geometry] # this is not an option
      @watermark       = options[:watermark]
      @file            = file
      @target_geometry = (options[:string_geometry_parser] || Geometry).parse(geometry)
      @format          = options[:format]
      @current_format  = File.extname(@file.path)
      @basename        = File.basename(@file.path, @current_format)
    end

    def make
      src = @file

      unless @watermark
        return src
      end

      dst = Tempfile.new([@basename, @format ? ".#{@format}" : ''])
      dst.binmode

      begin
        parameters = []
        parameters << transformation_command
        parameters << ":source"
        parameters << ":dest"

        parameters = parameters.flatten.compact.join(" ").strip.squeeze(" ")

        composite(parameters, :source => "#{File.expand_path(src.path)}#{'[0]'}", :dest => File.expand_path(dst.path))
      rescue Cocaine::ExitStatusError => e
        raise Paperclip::Error, "There was an error adding watermark for #{@basename}"
      rescue Cocaine::CommandNotFoundError => e
        raise Paperclip::Errors::CommandNotFoundError.new("Could not run the `composite` command. Please install ImageMagick.")
      end

      dst
    end

    def transformation_command
      trans = []
      trans << "-compose" << "atop"
      trans << "-gravity" << "SouthEast"
      trans << @watermark
      trans
    end

    def composite(arguments = "", local_options = {})
      Paperclip.run('composite', arguments, local_options)
    end
  end
end
