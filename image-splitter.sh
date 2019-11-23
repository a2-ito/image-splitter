IFS=$'\n'

############################################################################################
IGNORE_LIST=ignore.lst
SPLIT_RATE=50
_image_parentparent_dir=""
_image_output_dir=""
############################################################################################

image_splitter() {
  _image_dir=$1
  _split_rate_left=`echo "scale=5; 100-${SPLIT_RATE}"|bc`

  _dirname=${_image_output_dir}`basename "${_image_dir}"`
  if [ -e "${_dirname}" ]; then
    echo "  "skip - "${_dirname}"
		return
  fi
  _number_files=`ls -l "${_image_dir}" | wc -l`
  mkdir -p "${_dirname}"
  _count=0
  for _image in `find "${_image_dir}" -maxdepth 1 -type f -not -name "*.db"`;
  do
    _count=`expr ${_count} + 1`
    _height=`identify -format '%h' "${_image}"`
		if [ -z ${_height} ]; then
			echo "${_dirname}" "${_image_filename}"
			break
		fi
    _width=`identify -format '%w' "${_image}"`
    _image_filename=`basename "${_image}"`
    _fext="${_image_filename##*.}"
    _fname="${_image_filename%.*}"
    _progress=`echo "scale=5; ${_count}/${_number_files}*100" | bc`
    printf "                                                                      \r"
    printf "  %-20s progress:[%5.1f%% %4d/%4d] %15s\r" \
      "${_dirname}" ${_progress} ${_count} ${_number_files} "${_fname}"
    if [ ${_width} -gt ${_height} ]; then
      _split_width=`echo "scale=5; ${_width}*${SPLIT_RATE}/100"|bc`
      _output_image_name_right=${_fname}-1.${_fext}
      _output_image_name_left=${_fname}-2.${_fext}
      convert -crop ${SPLIT_RATE}%x100%+0+0 "${_image}" "${_dirname}/${_output_image_name_left}"
      convert -crop ${_split_rate_left}%x100%+${_split_width}%+0 "${_image}" "${_dirname}/${_output_image_name_right}"
    else
      cp "${_image}" "${_dirname}/"
    fi
  done
  echo;
}

for _image_parent_dir in `find "${_image_parentparent_dir}" -mindepth 1 -maxdepth 1 -type d`;
do
for _image_dir in `find "${_image_parent_dir}" -mindepth 1 -maxdepth 1 -type d`;
do
  _dirname=`basename "${_image_dir}"`
  if grep "${_image_dir}" "${IGNORE_LIST}" >/dev/null; then
		continue
	fi
  _number_files=`ls -l "${_image_dir}" | wc -l`
  _count=0
  _count_targets=0
  for _image in `find "${_image_dir}" -maxdepth 1 -type f -not -name "*.db"`;
  do
    _count=`expr ${_count} + 1`
    #echo identify -format '%h' "${_image}"
    #identify -format '%h' "${_image}"
    _height=`identify -format '%h' "${_image}"`
		if [ -z ${_height} ]; then
      echo identify -format '%h' "${_image}"
      identify -format '%h' "${_image}"
			echo "${_dirname}" "${_image_filename}"
			#break
		fi
    _width=`identify -format '%w' "${_image}"`
    _image_filename=`basename "${_image}"`
    printf "                                                                        \r"
    printf "%-24s %s [%3d(%3d)] - %10s %d %d\r" \
      "${_dirname:0:24}" "${_dirname/#* }" ${_count_targets} ${_count} "${_image_filename:-10}" ${_height} ${_width}
    if [ ${_width} -gt ${_height} ]; then
      _count_targets=`expr ${_count_targets} + 1`
    fi
    if [ "${_count_targets}" -gt 10 ]; then
      echo;
      image_splitter "${_image_dir}"
      break
    fi
    if [ "${_count}" -gt 30 ]; then
			echo "${_image_dir}" >> ${IGNORE_LIST}
      break
    fi
  done
done
done

