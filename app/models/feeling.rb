# Niko-cale plugin for Redmine
# Copyright (C) 2010  Yuki Kita
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
class Feeling < ActiveRecord::Base
  FEELING_TYPES = ["bad", "ordinary", "good"]
  belongs_to :user
  validates_inclusion_of :level, :in=>0...FEELING_TYPES.size

  FEELING_TYPES.each do |f|
    class_eval "def #{f}?;self.level == #{FEELING_TYPES.index(f)};end"
    class_eval "def #{f}(comment='')
self.level = #{FEELING_TYPES.index(f)}
self.comment = comment
self
end
"
    class_eval "def #{f}!(comment='')
self.#{f}(comment).save
self
end
"
  end
  def self.for(user)
    Feeling.find(:first, :conditions=>{:user_id=>user, :at=>Date.today}) || self.new{|f| f.at = Date.today; f.user = user}
  end
  def self.clean!
    Feeling.destroy_all
  end
  def self.exclude_before! date
    Feeling.destroy_all(["at <= ?", date])
  end
  def self.find_by_user_and_date_range user, date_range
    Feeling.find(:all, :conditions=>["user_id =? and at >= ? and at <= ?", user, date_range.first, date_range.last], :order=>"at ASC")
  end
end

class Mood < Feeling
  def add feeling
    if feeling.at == self.at
      @feelings ||= []
      @feelings << feeling
      true
    else
      false
    end
  end
  def level
    return nil unless @feelings
    average = @feelings.inject(0) {|result, feeling| result += feeling.level} / @feelings.size.to_f
    count = FEELING_TYPES.size
    1.upto(count) do |i|
      if average <= ((count - 1) / count.to_f) * i
        return (i - 1)
      end
    end
  end
end
