/*
 This file is part of SponSkrub.

 SponSkrub is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 SponSkrub is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with SponSkrub.  If not, see <https://www.gnu.org/licenses/>.
*/
import std.stdio;
import std.algorithm;
import std.conv;
import std.string;
import std.math;
import std.range;
import std.array;
import std.typecons;

import core.sys.posix.signal;

import ffwrap;
import sponsorblock;
import args;
import chapter;
import cut;

int main(string[] args)
{
	Args parsed_arguments = new Args([
			new ArgTemplate("sponskrub"),
			new ArgTemplate("video_id"),
			new ArgTemplate("input_filename"),
			new ArgTemplate("output_filename"),
			new ArgTemplate("chapter", true),
			new ArgTemplate("h", true),
			new ArgTemplate("exclude-sponsors", true),
			new ArgTemplate("exclude-intros", true),
			new ArgTemplate("exclude-outros", true),
			new ArgTemplate("exclude-interactions", true),
			new ArgTemplate("exclude-selfpromo", true),
			new ArgTemplate("exclude-nonmusic", true),
			new ArgTemplate("api-url", true, false, 1),
		]);
		
	parsed_arguments.parse(args);
	
	if (parsed_arguments.get_missing_arguments().length > 0) {
		writeln("Missing arguments: " ~ parsed_arguments.get_missing_arguments().join(" "));
		writeln();
	}
	
	if (parsed_arguments.unrecognised_arguments.length > 0) {
		writeln("Unrecognised arguments: " ~ parsed_arguments.unrecognised_arguments.join(" "));
		writeln();
	}
		
	if ("h" in parsed_arguments.flag_arguments || parsed_arguments.unrecognised_arguments.length > 0 || parsed_arguments.get_missing_arguments().length > 0) {
		writeln(
"Usage: sponskrub [-h] [-chapter] [-exclude-sponsors] [-exclude-intros] [-exclude-outros] [-exclude-interactions] [-exclude-selfpromo] [-exclude-nonmusic] [-api-url url] video_id input_filename output_filename

SponSkrub is an application for removing sponsors from downloaded Youtube video
 files, it requires an internet connection in order to consult the SponsorBlock
 database and ffmpeg must be installed.

Options:
 -h
   Display this help string

 -chapter
	 Mark sponsor spots as chapters rather than removing them.
	 Faster but leads to bigger file sizes
 
 -exclude-sponsors
   Exclude sponsors from the categories to be cut or marked as chapters

 -exclude-intros
   Exclude introductions from the categories to be cut or marked as chapters

 -exclude-outros
   Exclude outros from the categories to be cut or marked as chapters

 -exclude-interactions
   Exclude interactions from the categories to be cut or marked as chapters
 
 -exclude-selfpromo
   Exclude self-promotion from the categories to be cut or marked as chapters
 
 -exclude-nonmusic
   Exclude non-music portions of music videos from the categories to be cut or marked as chapters
   
 -api-url
   Specify the url where the API is located, defaults to sponsor.ajay.app
");
		return 1;
	}
	
	string api_url;
	if ("api-url" in parsed_arguments.flag_arguments) {
		api_url = parsed_arguments.flag_arguments["api-url"].join;
	} else {
		api_url = "sponsor.ajay.app";
	}
	auto video_id = parsed_arguments.positional_arguments[1];
	auto input_filename = parsed_arguments.positional_arguments[2];
	auto output_filename = parsed_arguments.positional_arguments[3];

	auto video_length = get_video_duration(input_filename);
	if (video_length is null) {
		writeln("Could not get video duration, is ffmpeg installed?");
		return 2;
	}
	writeln("Downloading video sponsor data");
	ClipTime[] sponsor_times;

	Categories[] categories = categories_from_arguments(parsed_arguments);
	
	if (categories.length == 0) {
		writeln("No categories were specified");
		return 4;
	} else {
		try {
			sponsor_times = get_video_skip_times(video_id, categories, api_url);
		}	catch (std.net.curl.HTTPStatusException e) {
			if (e.status == 404) {
				writeln("This video has no ad information available, either it has no ads or no one has logged any on SponsorBlock yet.");
				return 3;
			} else {
				writeln("Got %s the server must be broken, try again later".format(e.status));
				return 6;
			}
		} catch (std.net.curl.CurlException e) {
			writeln("Couldn't connect to the specified API url, try specifying a different one using the -api-url flag");
		}

		if (sponsor_times.length > 0) {		
			bool ffmpeg_status;
			
			if ("chapter" in parsed_arguments.flag_arguments) {
				writeln("Marking the shilling...");

				ChapterTime[] chapter_times; 
				ClipChapterTime[] new_chapter_times;
				
				chapter_times = get_chapter_times(input_filename);
				
				if (chapter_times.length == 0) {
					chapter_times = [ChapterTime("0", video_length, "sponskrub-content")];
				}
				
				new_chapter_times = merge_sponsor_times_with_chapters(sponsor_times, chapter_times);

				ffmpeg_status = add_ffmpeg_metadata(
					input_filename,
					output_filename,
					generate_chapters_metadata(new_chapter_times)
				);
			} else {
				auto content_times = timestamps_to_keep(sponsor_times, video_length);
				writeln("Surgically removing the shilling...");
				
				ffmpeg_status = run_ffmpeg_filter(
					input_filename,
					output_filename,
					cut_and_cat_clips_filter(content_times, get_file_category(input_filename)),
					get_file_category(input_filename)
				);
			}
			
			if (ffmpeg_status) {
				writeln("Done!");
				return 0;
			} else {
				writeln("There was an issue generating the output file, is ffmpeg installed? This could be a bug");
				return 5;
			}			
		} else {
			writeln("Nothing to be done.");
			return 3;
		}
	}
}

Categories[] categories_from_arguments(Args arguments) {
	Categories[] categories = [];
	if ("exclude-sponsors" !in arguments.flag_arguments) {
		categories ~= Categories.Sponsor;
	}
	if ("exclude-intros" !in arguments.flag_arguments) {
		categories ~= Categories.Intro;
	}
	if ("exclude-outros" !in arguments.flag_arguments) {
		categories ~= Categories.Outro;
	}
	if ("exclude-interactions" !in arguments.flag_arguments) {
		categories ~= Categories.Interaction;
	}
	if ("exclude-selfpromo" !in arguments.flag_arguments) {
		categories ~= Categories.SelfPromo;
	}
	if ("exclude-nonmusic" !in arguments.flag_arguments) {
		categories ~= Categories.NonMusic;
	}
	
	return categories;
}
