#!/usr/bin/env bash

# The stock camera in Google Pixel 8 uses unconventional filenames when saving both JPEG and RAW (DNG) files.
# It saves them with the suffixes ".RAW-01.COVER.jpg" and ".RAW-02.ORIGINAL.dng" instead of using the same base name with different extensions, as is far more common.
# This renames both of them to have the suffixes ".RAW.jpg" and ".RAW.dng" in keeping with common practice.

# NOTE: Motion photos with an accompanying RAW file are **NOT** renamed
# This is by design, as the JPEG file contains additional data and thus should not be subsumed under the RAW file in photo management software
# Such photos will have the suffixes ".RAW-01.MP.COVER.jpg" and ".RAW-02.ORIGINAL.dng", reflecting their non-overlapping contents

INPUT_DIR="Photos-source/pixel8"

RAW_JPG_SUFFIX=".RAW-01.COVER.jpg"
RAW_DNG_SUFFIX=".RAW-02.ORIGINAL.dng"
RAW_MOTION_PHOTO_JPG_SUFFIX=".RAW-01.MP.COVER.jpg"

counter=0
no_jpg_raw_photos=()
no_dng_raw_photos=()
motion_photo_raw_photos=()
target_jpg_exist_raw_photos=()
target_dng_exist_raw_photos=()

while read -r file; do
	if [ -n "$file" ]; then
		((counter++))

		input_file="$INPUT_DIR/$file"
		input_file_root_name="$(basename "$input_file" "$RAW_JPG_SUFFIX")"
		input_file_parent_dir="$(dirname "$input_file")"
		dng_file="$input_file_parent_dir/$input_file_root_name$RAW_DNG_SUFFIX"

		if [ -f "$dng_file" ]; then

			target_jpg_file="$input_file_parent_dir/$input_file_root_name.RAW.jpg"
			target_dng_file="$input_file_parent_dir/$input_file_root_name.RAW.dng"

			safe_to_rename=1

			if [ -f "$target_jpg_file" ]; then
				target_jpg_exist_raw_photos+=("$target_jpg_file")
				safe_to_rename=0
			fi
			if [ -f "$target_dng_file" ]; then
				target_dng_exist_raw_photos+=("$target_dng_file")
				safe_to_rename=0
			fi

			if [ $safe_to_rename -eq 1 ]; then
				echo "Renaming '$input_file' -> '$target_jpg_file'"
				echo "Renaming '$dng_file' -> '$target_dng_file'"
				mv -n "$input_file" "$target_jpg_file"
				mv -n "$dng_file" "$target_dng_file"
			fi

		else
			no_dng_raw_photos+=("$input_file")
		fi

	fi
done <<< "$(find "$INPUT_DIR" -type f -name '*'"$RAW_JPG_SUFFIX" -printf '%P\n')"

while read -r file; do
	if [ -n "$file" ]; then
		((jpg_counter++))

		input_file="$INPUT_DIR/$file"
		input_file_root_name="$(basename "$input_file" "$RAW_DNG_SUFFIX")"
		input_file_parent_dir="$(dirname "$input_file")"
		jpg_file="$input_file_parent_dir/$input_file_root_name$RAW_JPG_SUFFIX"
		motion_photo_jpg_file="$input_file_parent_dir/$input_file_root_name$RAW_MOTION_PHOTO_JPG_SUFFIX"

		if [ ! -f "$jpg_file" ]; then
			if [ -f "$motion_photo_jpg_file" ]; then
				motion_photo_raw_photos+=("$input_file")
			else
				no_jpg_raw_photos+=("$input_file")
			fi
		fi

	fi
done <<< "$(find "$INPUT_DIR" -type f -name '*'"$RAW_DNG_SUFFIX" -printf '%P\n')"

echo ""
echo "Renamed $((jpg_counter - ${#no_dng_raw_photos[@]} - ${#target_jpg_exist_raw_photos[@]} - ${#target_dng_exist_raw_photos[@]} - ${#motion_photo_raw_photos[@]} - ${#no_jpg_raw_photos[@]})) out of $counter pairs of *$RAW_JPG_SUFFIX and *$RAW_DNG_SUFFIX files"


if [ ${#no_dng_raw_photos[@]} -ne 0 ]; then
	echo ""
	echo "File pairs not renamed because of the following target jpg file names already exist:"
	for photo in "${target_jpg_exist_raw_photos[@]}"; do
		echo "$photo"
	done
	echo ""
fi

if [ ${#no_dng_raw_photos[@]} -ne 0 ]; then
	echo ""
	echo "File pairs not renamed because of the following target dng file names already exist:"
	for photo in "${target_dng_exist_raw_photos[@]}"; do
		echo "$photo"
	done
	echo ""
fi

if [ ${#motion_photo_raw_photos[@]} -ne 0 ]; then
	echo ""
	echo "*$RAW_DNG_SUFFIX files not renamed because it corresponds to a jpg containing a motion photo:"
	for photo in "${motion_photo_raw_photos[@]}"; do
		echo "$photo"
	done
	echo ""
fi

if [ ${#no_dng_raw_photos[@]} -ne 0 ]; then
	echo ""
	echo "*$RAW_JPG_SUFFIX files not renamed because there is no corresponding dng:"
	for photo in "${no_dng_raw_photos[@]}"; do
		echo "$photo"
	done
	echo ""
fi

if [ ${#no_jpg_raw_photos[@]} -ne 0 ]; then
	echo ""
	echo "*$RAW_DNG_SUFFIX files not renamed because there is no corresponding jpg:"
	for photo in "${no_jpg_raw_photos[@]}"; do
		echo "$photo"
	done
	echo ""
fi
