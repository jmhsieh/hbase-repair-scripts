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
NAME = "dumpregioninfo"

# Print usage for this script
def usage
  puts 'Usage: %s.rb <PATH_TO_REGIONINFO>' % NAME
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
if ARGV.size != 1
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

LOG.info(hri.toString())
if hri.isOffline
  LOG.info("OFFLINE")
end
if hri.isSplit
  LOG.info("SPLITTING")
end

hri.setSplit(true)
hri.setOffline(true)

newri = fs.makeQualified(Path.new(java.lang.String.new(ARGV[0] + ".split")))
os = fs.create(newri)
os.write(Writables.getBytes(hri));
# os.write('\n')
# os.write('\n')
# os.write(hri.toString())
os.close


LOG.info("Added to catalog: " + hri.toString())
