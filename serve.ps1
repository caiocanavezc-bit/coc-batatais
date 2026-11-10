param([int]$Port = 4173)

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$listener = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, $Port)
$listener.Start()

try {
    while ($true) {
        $client = $listener.AcceptTcpClient()
        # Um erro em uma requisição (ex.: navegador fecha a conexão no meio) não derruba o servidor
        try {
        $client.ReceiveTimeout = 5000
        $stream = $client.GetStream()
        $reader = [IO.StreamReader]::new($stream, [Text.Encoding]::ASCII, $false, 1024, $true)
        $requestLine = $reader.ReadLine()
        while (($line = $reader.ReadLine()) -ne '') { if ($null -eq $line) { break } }
        $requestTarget = if ($requestLine -match '^GET\s+([^\s]+)') { $Matches[1] } else { '/' }
        $requestPath = ([Uri]::new("http://localhost$requestTarget")).AbsolutePath
        $relativePath = [Uri]::UnescapeDataString($requestPath.TrimStart('/'))
        if ([string]::IsNullOrWhiteSpace($relativePath)) { $relativePath = 'index.html' }
        $candidate = [IO.Path]::GetFullPath((Join-Path $root $relativePath))

        if (-not $candidate.StartsWith($root, [StringComparison]::OrdinalIgnoreCase) -or -not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            $status = '404 Not Found'
            $bytes = [Text.Encoding]::UTF8.GetBytes('Not found')
            $contentType = 'text/plain; charset=utf-8'
        } else {
            $status = '200 OK'
            $extension = [IO.Path]::GetExtension($candidate).ToLowerInvariant()
            $contentType = switch ($extension) {
                '.html' { 'text/html; charset=utf-8' }
                '.css'  { 'text/css; charset=utf-8' }
                '.js'   { 'text/javascript; charset=utf-8' }
                '.svg'  { 'image/svg+xml' }
                '.png'  { 'image/png' }
                '.jpg'  { 'image/jpeg' }
                '.jpeg' { 'image/jpeg' }
                '.webp' { 'image/webp' }
                '.ico'  { 'image/x-icon' }
                default { 'application/octet-stream' }
            }
            $bytes = [IO.File]::ReadAllBytes($candidate)
        }

        $header = "HTTP/1.1 $status`r`nContent-Type: $contentType`r`nContent-Length: $($bytes.Length)`r`nCache-Control: no-store, no-cache, must-revalidate`r`nConnection: close`r`n`r`n"
        $headerBytes = [Text.Encoding]::ASCII.GetBytes($header)
        $stream.Write($headerBytes, 0, $headerBytes.Length)
        $stream.Write($bytes, 0, $bytes.Length)
        } catch {
            # ignora a requisição com problema e segue atendendo as próximas
        } finally {
            if ($stream) { $stream.Dispose() }
            $client.Close()
            $stream = $null
        }
    }
} finally {
    $listener.Stop()
}
