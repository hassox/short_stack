module Pancake
  module Generators
    class Short < Thor::Group
      include Thor::Actions

      def self.source_root
        File.join(File.dirname(__FILE__), "templates")
      end

      namespace "short"
      argument :stack_name, :banner => "Name of stack"

      desc "Generates a short stack"
      def stack
        say "Creating The Short Stack For #{stack_name}"
        directory "short/%stack_name%", stack_name
        template  File.join(self.class.source_root, "common/dotgitignore"), "#{stack_name}/.gitignore"
        template  File.join(self.class.source_root, "common/dothtaccess"),  "#{stack_name}/lib/#{stack_name}/public/.htaccess"
      end
    end
  end
end
