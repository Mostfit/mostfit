Naming issues
=============

This document lists issues encountered with the current naming scheme. Inconsistencies, vagueness and general impropriety.

Models and Libraries
--------------------

We're mixing up a lot of models and libraries in app/models, moving the non-datamapper models to lib would be a good idea.


Consistent id columns
---------------------

We're not being terribly consistent with association naming when we use non-standard indexes, specifically when associating staff members a managers or "updated_by" type associations. If we want to make clear the difference between changes made by managers, staff-members or users the association should reflect this as well as the id column naming. (e.g either created_by_user and created_by_user_id OR created_by and created_by_id, not a combination.)

Considering we often use many of these methods on models I recommend we go with the "full" naming, (e.g. created_by_user, validated_by_staff_member) to avoid confusion as to what model we're referring to.

I recommend we stick to 'standard' association naming and using :child_key options as little as possible.

Some examples listed below (a simple grep will show all). In some cases the naming is ok but use of :child_key is superfluous.

*   "Good" uses:
    AuditItem             belongs_to :assigned_to, :model => StaffMember

*   "Bad" uses:
    AccountBalance        belongs_to :verified_by, :child_key => [:verified_by_user_id], :model => 'User'
    Accrual               belongs_to :created_by, :child_key => [:created_by_user_id]
    ApplicableFee         belongs_to :waived_off_by, 'StaffMember', :child_key => [:waived_off_by_id]
    AssetRegister         belongs_to :manager, :child_key => [:manager_staff_id],  :model => 'StaffMember'
    AssetRegister         belongs_to :branch, :child_key => [:branch_id],         :model => 'Branch'

Of course this would be a huge pita to fix.


Hand-made associations
----------------------

There are several places where we have 'polymorphic' associations, for example in AuditItem:

    property :audited_model, String
    property :audited_id, Integer

    def object
      Kernel.const_get(audited_model).get(audited_id)
    end

or in ApplicableFee:

    property :applicable_id,   Integer, :index => true, :nullable => false
    property :applicable_type, Enum.send('[]', *FeeApplicableTypes), :index => true, :nullable => false

    def parent
      Kernel.const_get(self.applicable_type).get(self.applicable_id)
    end

As there is no standard for polymorphic associations in DM, we should at least set some rules to name these associations consistently. Or we could look at dm-is-remixable which seems to fill a similar role.

Other models with similar associations:

*   AuditTrail
*   Comment
*   Document


Nullable
--------

Not so much a naming issue, but in a number of places we use :nullable => false, which was deprecated in DM 0.10.2 in favor of :required => true

We also have a bunch of places where :nullable => false is set and later validates_presence. 


Constants
---------

We have a large number of constants in config/constants.rb ripe for renaming. I don't think we need examples here as they are quite obvious, but Types and Methods (used only in the Bookmark model) for starters.

