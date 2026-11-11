# Sincroniza esta pasta com o GitHub, nos dois sentidos:
#   1. baixa o que foi alterado em outros computadores;
#   2. envia o que foi alterado neste computador (e o site publicado se atualiza sozinho).
#
# Uso (no PowerShell, dentro da pasta do projeto):
#   .\sincronizar.ps1                          -> mensagem padrão
#   .\sincronizar.ps1 "Troca as fotos da equipe"  -> com uma mensagem sua
#
# Primeira vez em outro computador:
#   git clone https://github.com/caiocanavezc-bit/coc-batatais.git
#   cd coc-batatais
#   .\sincronizar.ps1
#
# Rode sempre ANTES de começar a mexer e DEPOIS de terminar.

param([string]$Mensagem = "Atualiza o site")

Set-Location $PSScriptRoot

Write-Host "Baixando alterações de outros computadores..." -ForegroundColor Cyan
git pull --rebase --autostash
if ($LASTEXITCODE -ne 0) {
    Write-Host "Conflito ao juntar as alterações. Nada foi enviado; resolva o conflito (ou peça ajuda) e rode de novo." -ForegroundColor Red
    exit 1
}

if (git status --porcelain) {
    Write-Host "Enviando as alterações deste computador..." -ForegroundColor Cyan
    git add -A
    git commit -m $Mensagem
    git push
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Pronto. O site publicado se atualiza em 1 a 2 minutos:" -ForegroundColor Green
        Write-Host "https://caiocanavezc-bit.github.io/coc-batatais/"
    }
} else {
    Write-Host "Tudo sincronizado. Nada novo para enviar." -ForegroundColor Green
}
