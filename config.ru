use Rack::CommonLogger
use Rack::ShowExceptions
use Rack::Deflater

run Rack::File.new('public')