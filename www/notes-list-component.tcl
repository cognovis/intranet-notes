# -------------------------------------------------------------
# /packages/intranet-notes/www/notes-list-component.tcl
#
# Copyright (c) 2007 ]project-open[
# All rights reserved.
#
# Author: frank.bergmann@project-open.com
#

# -------------------------------------------------------------
# Variables:
#	object_id:integer
#	return_url

if {![info exists object_id]} {
    ad_page_contract {
	@author frank.bergmann@project-open.com
    } {
	object_id:integer
    }
}

if {![info exists return_url] || "" == $return_url} { set return_url [im_url_with_query] }
set user_id [ad_maybe_redirect_for_registration]
set new_note_url [export_vars -base "/intranet-notes/new" {object_id return_url}]

# Check the permissions
# Permissions for all usual projects, companies etc.
set object_type [db_string acs_object_type "select object_type from acs_objects where object_id=:object_id"]
set perm_cmd "${object_type}_permissions \$user_id \$object_id object_view object_read object_write object_admin"
eval $perm_cmd


# ----------------------------------------------------
# Create a "multirow" to show the results

multirow create notes note_type note note_formatted

if {$object_read} {

    set notes_sql "
	select	n.*,
		im_category_from_id(n.note_type_id) as note_type,
                o.last_modified,
                o.modifying_user, o.creation_user
	from	im_notes n, acs_objects o
	where	n.object_id = :object_id
        and o.object_id = n.note_id
        order by o.last_modified desc
    "
    
    db_multirow -extend { note_date note_user note_formatted notes_edit_url } notes notes_query $notes_sql {

	regsub -all {[^0-9a-zA-Z]} $note_type "_" note_type_key
	set note_type [lang::message::lookup "" intranet-notes.$note_type_key $note_type]
	set note [template::util::richtext::get_property html_value $note]
	set note_formatted [im_note_format -note_type_id $note_type_id -note $note]
	set notes_edit_url "${new_note_url}&note_id=$note_id"
	set note_date [lc_time_fmt $last_modified "%x" [lang::user::locale]]
	if {$modifying_user eq ""} {set modifying_user $creation_user}
	set note_user [person::name -person_id $modifying_user]
    }
}
