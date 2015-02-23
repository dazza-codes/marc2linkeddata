#!/usr/bin/env ruby



module Marc2LinkedData

  class Utils

    def self.stack_trace(e, record=nil)
      $stderr.write "\n"
      $stderr.write "ERROR\n"
      $stderr.write e.message
      $stderr.write e.backtrace
      $stderr.write "\n"
      $stderr.write record.to_s
      $stderr.write "\n"
    end

    # Count all the records in the MARC file, by
    # parsing the record leader, see
    # http://www.loc.gov/marc/bibliographic/bdleader.html
    # http://www.loc.gov/marc/authority/adleader.html
    def self.marc_type_count(marc_filename)
      # 06 - Type of record
      # a - Language material
      # c - Notated music
      # d - Manuscript notated music
      # e - Cartographic material
      # f - Manuscript cartographic material
      # g - Projected medium
      # i - Nonmusical sound recording
      # z - Authority data
      record_types = {
          :a_language_material => 0,
          :c_notated_music => 0,
          :d_manuscript_notated_music => 0,
          :e_cartographic_material => 0,
          :f_manuscript_cartographic_material => 0,
          :g_projected_medium => 0,
          :i_nonmusical_sound_recording => 0,
          :z_authority_data => 0
      }
      marc_file = File.open(marc_filename,'r')
      until marc_file.eof?
        begin
          leader = Marc2LinkedData::Utils.parse_leader(marc_file)
          marc_file.seek(leader[:length], IO::SEEK_CUR)
          case leader[:type]
            when 'a'
              record_types[:a_language_material] += 1
            when 'c'
              record_types[:c_notated_music] += 1
            when 'd'
              record_types[:d_manuscript_notated_music] += 1
            when 'e'
              record_types[:e_cartographic_material] += 1
            when 'f'
              record_types[:f_manuscript_cartographic_material] += 1
            when 'g'
              record_types[:g_projected_medium] += 1
            when 'i'
              record_types[:i_nonmusical_sound_recording] += 1
            when 'z'
              record_types[:z_authority_data] += 1
          end
        rescue => e
          Marc2LinkedData::Utils.stack_trace(e, leader)
          binding.pry if CONFIG.debug
        end
      end
      marc_file.close
      record_types
    end

    def self.parse_leader(file_handle, leader_bytes=24)
      # example:
      #record.leader
      #=> "00774cz  a2200253n  4500"
      # 00-04: '00774' - record length
      # 05:    'c' - corrected or revised
      # 06:    'z' - always 'z' for authority records
      # 09:    'a' - UCS/Unicode
      # 12-16: '00253' - base address of data, Length of Leader and Directory
      # 17:    'n' - Complete authority record
      # leader_status_codes = {
      #     'a' => 'Increase in encoding level',
      #     'c' => 'Corrected or revised',
      #     'd' => 'Deleted',
      #     'n' => 'New',
      #     'o' => 'Obsolete',
      #     's' => 'Deleted; heading split into two or more headings',
      #     'x' => 'Deleted; heading replaced by another heading'
      # }
      leader = file_handle.read(leader_bytes)
      file_handle.seek(-1 * leader_bytes, IO::SEEK_CUR)
      {
          :length => leader[0..4].to_i,
          :status => leader[5],  # leader_status_codes[ record.leader[5] ]
          :type => leader[6],    # always 'z' for authority records
          :encoding => leader[9],  # translate letter code into ruby encoding string
          :data_address => leader[12..16].to_i,
          :complete => leader[17].include?('n')
      }
    end

  end

end

