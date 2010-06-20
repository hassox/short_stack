module Pancake
  module Generators
    class Micro < Thor::Group
      include Thor::Actions

      def self.source_root
        File.join(File.dirname(__FILE__), "templates")
      end

      namespace "micro"
      argument :stack_name, :banner => "Name of stack"

      desc "Generates a Micro stack"
      def stack
        say "Creating The Stack For #{stack_name}"
        directory "micro/%stack_name%", stack_name
        template  File.join(self.class.source_root, "common/dotgitignore"), "#{stack_name}/.gitignore"
        template  File.join(self.class.source_root, "common/dothtaccess"),  "#{stack_name}/public/.htaccess"
        template  File.join(self.class.source_root, "common/Gemfile"), "#{stack_name}/Gemfile"
      end
    end
  end
end
