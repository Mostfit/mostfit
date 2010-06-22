# dependencies are generated using a strict version, don't forget to edit the dependency versions when upgrading.
merb_gems_version = "1.0.13"
dm_gems_version   = "0.10.1"
do_gems_version   = "0.10.0"

# For more information about each component, please read http://wiki.merbivore.com/faqs/merb_components
dependency "merb-core", merb_gems_version
dependency "merb-action-args", merb_gems_version
dependency "merb-assets", merb_gems_version
# dependency("merb-cache", merb_gems_version) do
#   Merb::Cache.setup { register(Merb::Cache::FileStore) }
# end
dependency "merb-helpers", merb_gems_version
dependency "merb-mailer", merb_gems_version
dependency "merb-haml", merb_gems_version
dependency "merb-slices", merb_gems_version
dependency "merb-auth-core", merb_gems_version
dependency "merb-auth-more", merb_gems_version
dependency "merb-auth-slice-password", merb_gems_version
dependency "merb-param-protection", merb_gems_version
dependency "merb-exceptions", merb_gems_version

dependency "merb_datamapper", merb_gems_version

dependency "data_objects", do_gems_version
#dependency "do_sqlite3", do_gems_version  # most development
dependency "do_mysql", do_gems_version    # most production

dependency "dm-core", dm_gems_version
dependency "dm-aggregates", dm_gems_version
dependency "dm-migrations", dm_gems_version
dependency "dm-timestamps", dm_gems_version
dependency "dm-types", dm_gems_version
dependency "dm-validations", dm_gems_version
dependency "dm-serializer", dm_gems_version
dependency "dm-observer", dm_gems_version
dependency "dm-is-tree", dm_gems_version

dependency "dm-paperclip"
dependency "merb-gen", merb_gems_version
dependency "dm-pagination"
dependency "htmldoc"
dependency "dm-pagination"
#dependency "pdf-writer"
dependency "uuid"
#dependency "dm-is-paginated"
