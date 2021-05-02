# SponSkrub

This is a fork of [sponskrub](https://github.com/faissaloo/SponSkrub) primarily intended for use with [yt-dlp](https://github.com/pukkandan/yt-dlp)

## Main Changes

* Provide windows binary (only x86 for now)
* All sections are included by default and all switches are changed to `--exclude-`
* Removed `youtube-dl-sponskrub` since [yt-dlp](https://github.com/pukkandan/yt-dlp) has direct [sponskrub integraion](https://github.com/pukkandan/yt-dlp#sponSkrub-options-sponsorblock)

**PS**: I am not familar enough in DLang to add features or resolve issues (unless the issue is specific to this fork). It is probably better to make the request in [faissaloo/sponskrub](https://github.com/faissaloo/SponSkrub). I will merge any commits made there into this fork.

## Description
SponSkrub is a command line utility for removing sponsors from downloaded Youtube videos.

FFmpeg and FFprobe are required for this application to work. Additionally, `libcurl.dll` is necessary for windows. A copy of libcurl x86 is provided along with the releases.

It makes use of the [SponsorBlock API](https://github.com/ajayyy/SponsorBlockServer#api-docs) and I'd recommend installing the extension and maybe contributing some sponsorship times when you're ever bored.

You can build `sponskrub` by running `dub build`.

## Usage

    sponskrub [options] [--] video_id input_filename output_filename

## Options

    -h                     Display help
    -chapter               Mark sections as chapters rather than removing them
    -exclude-sponsors      Do not remove sponsors
    -exclude-intros        Do not remove introductions
    -exclude-outros        Do not remove outros
    -exclude-interactions  Do not remove interactions
    -exclude-selfpromo     Do not remove self-promotion
    -exclude-nonmusic      Do not remove non-music portions of music videos
    -proxy                 Route all trafic through this proxy
    -no-id                 Searches for sponsor data by the partial hash of the
                           video id instead of directly requesting it
    -no-keep-date          Do not give the output file the same modification date
                           as the input file
    -api-url               Specify the url where the API is located, defaults to
                           sponsor.ajay.app
