require "chunked"

module Nya
  module Storage
    class Reader
      alias CReader = Chunked::IndexedReader(UInt64)

      @readers = Hash(String, CReader).new
      @files_index = Hash(String, String).new

      protected def add_file(name : String)
        @readers[file] = CReader.new(File.open(file))
        @readers[file].index_chunks!
        idx = 0
        @readers[file][0u64].each_line("\0") do |line|
          unless line.nil?
            @files_index[line.chomp] = "#{file}/$#{idx}"
            idx += 1
          end
        end
      end

      def initialize(@files : Array(String))
        @files.each do |file|
          add_file file
        end
      end

      def read_file(name)
        if @files_index.has_key?(name)
          name, idx = @files_index[name].split("/$",2)
          @readers[file][idx.to_u64]
        else
          File.open(name)
        end
      end

      def read_file(name, &block : IO->Void)
        begin
          f = read_file name
          block.call f
        ensure
          f.close
        end
      end

      def self.init(files)
        @@instance = new files
      end


      def read_file(*args)
        @@instance.read_file(*args)
      end
    end
  end
end
