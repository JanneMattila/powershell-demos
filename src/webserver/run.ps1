$tcpListener = New-Object System.Net.Sockets.TcpListener 8080
$tcpListener.Start()

while ($true) {
    $tcpClient = $tcpListener.AcceptTcpClient()
    $stream = $tcpClient.GetStream()
    $reader = New-Object System.IO.StreamReader $stream
    $writer = New-Object System.IO.StreamWriter $stream

    $request = $reader.ReadLine()

    if ($null -eq $request -or $request.Contains("favicon.ico")) {
        $writer.WriteLine("HTTP/1.1 404 Not Found")
        $writer.WriteLine("Content-Type: text/html")
        $writer.WriteLine("")
    }
    elseif ($request.Contains("?code=")) {
        $start = $request.IndexOf(("=")) + 1
        $end = $request.IndexOf("&", $start) - 1
        $code = $request.Substring($start, $end - $start + 1)
        $writer.WriteLine("HTTP/1.1 200 OK")
        $writer.WriteLine("Content-Type: text/html")
        $writer.WriteLine("")
        $writer.WriteLine("<html><body>Code: $code</body></html>")
    }
    else {
        $writer.WriteLine("HTTP/1.1 200 OK")
        $writer.WriteLine("Content-Type: text/html")
        $writer.WriteLine("")
        $writer.WriteLine("<html><body>Hello, World!</body></html>")
    }

    $writer.Flush()
    $stream.Close()
    $tcpClient.Close()
}

$request

$tcpListener.Stop()
