The Mostfit Business Rules Engine
=================================

It consists of:

  1. Main Files - `lib/rules.rb`
  2. View - `app/views/rules/`
  3. Controller - `app/controllers/rules.rb`
  4. Model - `app/models/rule.rb`

This rules engine can handle multiple conditions (connected with `and`
and `or` operators) simultaneously and since the rules are compiled to
respective models (using validates_with_method of `datamapper`), it produces
minimal overhead.

The rules can be manipulated in run-time without re-booting the server.


## Internals

Internally, the rules engine uses BasicCondition(B) class (in lib/rules.rb) to represent a simple condition(S), a complex condition(C1) is either
C1 = [:not, C2]
or
C1 = [:and, C2, C3]
or
C1 = [:or. C2, C3]
or
C1 = [is_basic_condition = true, B]


