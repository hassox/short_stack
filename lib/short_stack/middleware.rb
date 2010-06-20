require 'rack-rescue'
require 'wrapt'

Pancake.before_build do
  unless Pancake::StackMiddleware[:rescue] || Pancake::StackMiddleware[Rack::Rescue]
    Pancake.stack(:rescue).use(Rack::Rescue)
  end

  unless Pancake::StackMiddleware[:layout] || Pancake::StackMiddleware[Wrapt]
    Pancake.stack(:layout).use(Wrapt) do |wrapt|
      wrapt.defer!
    end
  end
end
