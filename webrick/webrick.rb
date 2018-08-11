require 'webrick'

srv = WEBrick::HTTPServer.new({
  DocumentRoot:   './',
  BindAddress:    '127.0.0.1',
  Port:           8080,
})

#srv.mount('/', WEBrick::HTTPServlet::FileHandler, 'index.html')

srv.start
