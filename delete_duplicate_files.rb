# frozen_string_literal: true

require 'pathname'

## FLAGS ##
DELETE_EXTS     = ['.mp3', '.m4p'].freeze
DIR             = '/Music'
FORCE           = false
IGNORE_PATTERNS = [/Syno/, /eaDir/].freeze
PRETEND         = false
QUIET           = false

def recurse(pathname)
  relevant_paths = ignore_paths(pathname.children)
  process_directories(relevant_paths)
  process_files(relevant_paths)
end

def ignore_paths(paths, patterns = IGNORE_PATTERNS.dup)
  return paths if patterns.empty?

  pattern = patterns.pop
  new_paths = paths.reject { |path| path.to_s =~ pattern }
  ignore_paths(new_paths, patterns)
end

def process_directories(pathname)
  directories = pathname.select(&:directory?)
  return if directories.empty?
  directories.map { |dir| recurse(dir) }
end

def process_files(pathname)
  files = pathname.select(&:file?)
  return if files.empty?

  find_duplicates(files)
end

def find_duplicates(files)
  duplicates = files.group_by { |file| file.sub_ext('') }.select { |_, v| v.size > 1 }.values
  return if duplicates.empty?

  print_to_console files.first.dirname.to_s
  print_to_console '=========='
  duplicates.map { |duplicate| process_duplicate_set(duplicate) }
  print_to_console ''
end

def process_duplicate_set(files)
  sorted_files = files.sort

  file_basename = sorted_files.first.basename.sub_ext('').to_s
  print_to_console("Found duplicate #{file_basename}")

  files_to_delete = sorted_files.select { |file| DELETE_EXTS.include? file.extname }
  files_to_delete.map { |file| delete_file(file) }
end

def delete_file(file)
  unless FORCE
    return unless prompt_yes("Delete #{file}?")
  end

  print_to_console "Deleting file: #{file}"

  return if PRETEND

  file.delete
end

def print_to_console(string)
  return if QUIET
  puts string
end

def prompt_yes(string)
  puts "#{string} [y|N] "
  answer = gets.chomp
  return false if answer.empty?
  return true if answer[0].casecmp('y')
  false
end

root = Pathname.new(DIR)
abort("#{DIR} is not a directory") unless root.directory?
recurse root
