#
# Copyright 2009 The Apache Software Foundation
#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Script adds a table back to a running hbase.
# Currently only works on if table data is in place.
#
# To see usage for this script, run:
#
#  ${HBASE_HOME}/bin/hbase org.jruby.Main addtable.rb
#
include Java
import org.apache.hadoop.hbase.util.Bytes
import org.apache.hadoop.hbase.HConstants
import org.apache.hadoop.hbase.regionserver.HRegion
import org.apache.hadoop.hbase.HRegionInfo
import org.apache.hadoop.hbase.client.HTable
import org.apache.hadoop.hbase.client.Delete
import org.apache.hadoop.hbase.client.Put
import org.apache.hadoop.hbase.client.Scan
import org.apache.hadoop.hbase.HTableDescriptor
import org.apache.hadoop.hbase.HBaseConfiguration
import org.apache.hadoop.hbase.util.FSUtils
import org.apache.hadoop.hbase.util.Writables
import org.apache.hadoop.fs.Path
import org.apache.hadoop.fs.FileSystem
import org.apache.commons.logging.LogFactory

# Name of this script
NAME = "add_region"

# Print usage for this script
def usage
  puts 'Usage: %s.rb <PATH_TO_REGIONINFO> <PATH_TO_SPLITA> <PATH_TO_SPLITB>' % NAME
  exit!
end

# Get configuration to use.
c = HBaseConfiguration.create()

# Set hadoop filesystem configuration using the hbase.rootdir.
# Otherwise, we'll always use localhost though the hbase.rootdir
# might be pointing at hdfs location.
c.set("fs.default.name", c.get(HConstants::HBASE_DIR))
fs = FileSystem.get(c)

# Get a logger and a metautils instance.
LOG = LogFactory.getLog(NAME)

# Check arguments
if ARGV.size != 3
  usage
end

# Get cmdline args.
regioninfo = fs.makeQualified(Path.new(java.lang.String.new(ARGV[0])))
if not fs.exists(regioninfo)
  raise IOError.new("regioninfo " + regioninfo.toString() + " doesn't exist!")
end
is = fs.open(regioninfo)
hri = HRegionInfo.new()
hri.readFields(is)
is.close()

regioninfoA = fs.makeQualified(Path.new(java.lang.String.new(ARGV[1])))
if not fs.exists(regioninfoA)
  raise IOError.new("regioninfoA " + regioninfoA.toString() + " doesn't exist!")
end
is = fs.open(regioninfoA)
hriA = HRegionInfo.new()
hriA.readFields(is)
is.close()

regioninfoB = fs.makeQualified(Path.new(java.lang.String.new(ARGV[2])))
if not fs.exists(regioninfoB)
  raise IOError.new("regioninfoB " + regioninfoB.toString() + " doesn't exist!")
end
is = fs.open(regioninfoB)
hriB = HRegionInfo.new()
hriB.readFields(is)
is.close()


p = Put.new(hri.getRegionName())
p.add(HConstants::CATALOG_FAMILY, HConstants::REGIONINFO_QUALIFIER, Writables.getBytes(hri))
p.add(HConstants::CATALOG_FAMILY, HConstants::SPLITA_QUALIFIER, Writables.getBytes(hriA))
p.add(HConstants::CATALOG_FAMILY, HConstants::SPLITB_QUALIFIER, Writables.getBytes(hriB))
metaTable = HTable.new(c, HConstants::META_TABLE_NAME)
metaTable.put(p)
LOG.info("Added to catalog: " + hri.toString() )
LOG.info(" splitA: " + hriA.toString())
LOG.info(" splitB: " + hriB.toString())
