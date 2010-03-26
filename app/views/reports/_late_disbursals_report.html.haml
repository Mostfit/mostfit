=partial :form
- length = 6
%table.report
  %tr.header
    %th{:width => '20%'}
      Date
    %th{:width => '20%'}
      Loan
    %th{:width => '20%'}
      Client
    %th
      Scheduled Disbursal Date
    %th
      Days delayed
    %th
      Status
  - org_total = 0
  - @data.each do |branch, centers|
    -branch_total = 0
    %tr.branch
      %td{:colspan => length}
        = branch.name
    - centers.each do |center, loans|
      -center_total = 0
      %tr.center
        %td{:colspan => length}
          = center.name
      - loans.each do |l|
        -center_total += l.amount
        %tr.group
          %td
            = @report.date
          %td
            = l.description
          %td
            = l.client.name
          %td 
            = l.scheduled_disbursal_date
          %td
            = @report.date - l.scheduled_disbursal_date
          %td
            = l.get_status(@report.date)
      %tr.center_total
        %td
          Center total
        %td
          =center_total
          -branch_total+=center_total
        -4.times do
          %td
    %tr.branch_total
      %td
        Branch total
      %td
        -org_total+=branch_total
        =branch_total
      -4.times do
        %td
  %tr.org_total
    %td
      Total
    %td
      =org_total
    -4.times do
      %td
