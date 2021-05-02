@echo off
setlocal

set "dPath=D:\DLang\dmd2\windows\bin"
set "LINKCMD=%dPath%\optlink.exe"

del sponskrub.exe
"%dPath%\dub" build --yes --force --build release --arch x86 :sponskrub
