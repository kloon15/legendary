meta:
  id: ue_manifest
  file-extension: manifest
  endian: le
seq:
  - id: magic
    contents: [0x0C, 0xC0, 0xBE, 0x44]
  - id: header_size
    type: u4
  - id: header
    size: header_size - 8
    type: header
  - id: body_compressed
    size-eos: true
    type: body
    process: zlib
    if: header.stored_as == stored_as_flag::compressed
  - id: body_uncompressed
    size-eos: true
    type: body
    if: header.stored_as == stored_as_flag::uncompressed
types:
  header:
    seq:
      - id: size_uncompressed
        type: u4
      - id: size_compressed
        type: u4
      - id: sha1_hash
        size: 20
      - id: stored_as
        type: u1
        enum: stored_as_flag
      - id: version
        type: u4
  body:
    seq:
      - id: meta_size
        type: u4
      - id: metadata
        size: meta_size - 4
        type: metadata
      - id: cdl_size
        type: u4
      - id: chunk_data_list
        type: chunk_data_list
        size: cdl_size - 4
      - id: fml_size
        type: u4
      - id: file_manifest_list
        type: file_manifest_list
        size: fml_size - 4
      - id: custom_data_size
        type: u4
      - id: custom_fields
        type: custom_fields
        size: custom_data_size - 4
  metadata:
    seq:
      - id: data_version
        type: u1
      - id: feature_level
        type: u4
      - id: is_file_data
        type: u1
      - id: app_id
        type: u4
      - id: app_name
        type: fstring
      - id: build_version
        type: fstring
      - id: launch_exe
        type: fstring
      - id: launch_command
        type: fstring
      - id: prereq_ids_num
        type: u4
      - id: prereq_ids
        type: fstring
        repeat: expr
        repeat-expr: prereq_ids_num
      - id: prereq_name 
        type: fstring
      - id: prereq_path 
        type: fstring
      - id: prereq_args 
        type: fstring
      - id: build_id
        type: fstring
        if: data_version > 0
  chunk_data_list:
    seq:
      - id: version
        type: u1
      - id: count
        type: u4
      - id: guids
        size: 16
        repeat: expr
        repeat-expr: count
      - id: ue_hashes
        type: u8
        repeat: expr
        repeat-expr: count
      - id: sha_hashes
        size: 20
        repeat: expr
        repeat-expr: count
      - id: group_nums
        type: u1
        repeat: expr
        repeat-expr: count
      - id: window_sizes
        type: u4
        repeat: expr
        repeat-expr: count
      - id: file_sizes
        type: u4
        repeat: expr
        repeat-expr: count
  file_manifest_list:
    seq:
      - id: version
        type: u1
      - id: count
        type: u4
      - id: filenames
        type: fstring
        repeat: expr
        repeat-expr: count
      - id: symlink_targets
        type: fstring
        repeat: expr
        repeat-expr: count
      - id: sha_hashes
        size: 20
        repeat: expr
        repeat-expr: count
      - id: flags
        type: u1
        enum: file_flags
        repeat: expr
        repeat-expr: count
      - id: tags
        type: tags
        repeat: expr
        repeat-expr: count
      - id: chunk_parts
        type: chunk_parts
        repeat: expr
        repeat-expr: count
      - id: md5_hashes
        if: version > 0
        type: md5_hash
        repeat: expr
        repeat-expr: count
      - id: mime_types
        if: version > 0
        type: fstring
        repeat: expr
        repeat-expr: count
      - id: sha256_hashes
        if: version > 1
        size: 32
        repeat: expr
        repeat-expr: count
  custom_fields:
    seq:
      - id: version
        type: u1
      - id: count
        type: u4
      - id: keys
        type: fstring
        repeat: expr
        repeat-expr: count
      - id: values
        type: fstring
        repeat: expr
        repeat-expr: count
  fstring:
    seq:
      - id: length
        type: s4
      - id: value_ascii
        size: length
        type: str
        encoding: 'ASCII'
        if: length >= 0
      - id: value_utf16
        size: -2 * length
        type: str
        encoding: 'UTF-16LE'
        if: length < 0
    instances:
      value:
        value: 'length >= 0 ? value_ascii : value_utf16'
        if: length >= 0 or length < 0
  tags:
    seq:
      - id: count
        type: u4
      - id: tag
        type: fstring
        repeat: expr
        repeat-expr: count
  chunk_parts:
    seq:
      - id: count
        type: u4
      - id: elements
        type: chunk_part_entry
        repeat: expr
        repeat-expr: count
  chunk_part_entry:
    seq:
      - id: entry_size
        type: u4
      - id: chunk_part
        type: chunk_part
        size: entry_size - 4
  chunk_part:
    seq:
      - id: guid
        size: 16
      - id: offset
        type: u4
      - id: size
        type: u4
  md5_hash:
    seq:
      - id: has_md5
        type: u4
      - id: md5
        size: 16
        if: has_md5 != 0
instances:
  body:
    value: 'header.stored_as == stored_as_flag::compressed ? body_compressed : body_uncompressed'
    if: header.stored_as == stored_as_flag::compressed or header.stored_as == stored_as_flag::uncompressed
enums:
  stored_as_flag:
    0x0: uncompressed
    0x1: compressed
  file_flags:
    0x0: none
    0x1: read_only
    0x2: compressed
    0x4: unix_executable