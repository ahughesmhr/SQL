-- testing
select 
a.name,
a.owneridname,
a.industrycodename,
isnull(ldate.ldate,0) as "Last Purchase",
isnull(comp.total,0) as "Complaints",
isnull((cast(totalwon.volume as decimal) / (totalwon.volume + isnull(totalopen.volume,0) + isnull(totallost.volume,0))),0) as "Win Ratio",
cast(isnull(modulest.total,0) - isnull(modulesni.total,0) as decimal) / isnull(modulest.total,1) "modules implemented ratio",
isnull(defects.total,0) "defects",
isnull(ca.avdaystoclose,0) "average time case open",
isnull(ct.total,0) "total cases",
isnull(lc.lastcall,0) "last case",
isnull(totalwon.volume,0) won,
isnull(totallost.volume,0) lost,
isnull(modulesni.total,0) "Not Implemented",
isnull(modulest.total,0) "Total Bought",
isnull(totalopen.volume,0) opendeals
from
[msl-svr267].crm_mscrm.dbo.FilteredAccount a
left outer join
(select accountid,max(new_contractawarddate) ldate
from [msl-svr267].crm_mscrm.dbo.filteredopportunity
where statecodename = 'Won'
group by accountid) ldate
on ldate.accountid = a.accountid
left outer join
(select accountid,count(*) volume
from [msl-svr267].crm_mscrm.dbo.filteredopportunity
where statecodename = 'Won'
group by accountid) totalwon
on totalwon.accountid = a.accountid
left outer join
(select accountid,count(*) volume
from [msl-svr267].crm_mscrm.dbo.filteredopportunity
where statecodename = 'Lost'
and new_probability in (30,40,10,12,13,14,15)
group by accountid) totallost
on totallost.accountid = a.accountid
left outer join
(select accountid,count(*) volume
from [msl-svr267].crm_mscrm.dbo.filteredopportunity
where statecodename = 'Open'
and new_probability in (30,40,10,12,13,14,15)
group by accountid) totalopen
on totalopen.accountid = a.accountid
left outer join
(select mhr_accountid,count(*) total
from [msl-svr267].crm_mscrm.dbo.Filteredmhr_software
where mhr_stagename != 'Live'
group by mhr_accountid
) modulesni
on modulesni.mhr_accountid = a.accountid
left outer join
(select mhr_accountid,count(*) total
from [msl-svr267].crm_mscrm.dbo.Filteredmhr_software
group by mhr_accountid
) modulest
on modulest.mhr_accountid = a.accountid
left outer join
(select account_reference__c,count(*) total
  from [salesforce backups].dbo.[case] c
  inner join [salesforce backups].dbo.[account] a
  on c.accountid = a.id
  inner join [salesforce backups].dbo.defect__c d
  on c.defect__c = d.id
  where d.status__c != 'Complete'
  group by account_reference__c
) defects
on defects.account_reference__c = a.accountid
left outer join
(select 
a.name,
avg((DATEDIFF(dd, c.createddate, c.ClosedDate) + 1)
  -(DATEDIFF(wk, c.createddate, c.ClosedDate) * 2)
  -(CASE WHEN (DATENAME(dw, c.createddate) = 'Sunday' or DATENAME(dw, c.ClosedDate) = 'Sunday') THEN 1 ELSE 0 END)
  -(CASE WHEN (DATENAME(dw, c.Createddate) = 'Saturday' or DATENAME(dw, c.ClosedDate) = 'Saturday') THEN 1 ELSE 0 END)) avdaystoclose
from [salesforce backups].dbo.[case] c
inner join [salesforce backups].dbo.[account] a on c.accountid = a.id
where c.Status = 'Closed'
and c.createddate >= dateadd(year,-1,getdate())
group by a.name) ca
on ca.name collate Latin1_General_CI_AI = a.name
left outer join
(select 
a.name,
count(*) total
from [salesforce backups].dbo.[case] c
inner join [salesforce backups].dbo.[account] a on c.accountid = a.id
where c.Status = 'Closed'
and c.createddate >= dateadd(year,-1,getdate())
group by a.name) ct
on ct.name collate Latin1_General_CI_AI = a.name
left outer join
(select 
a.name,
datediff(dd,max(c.createddate),getdate()) lastcall
from [salesforce backups].dbo.[case] c
inner join [salesforce backups].dbo.[account] a on c.accountid = a.id
group by a.name) lc
on lc.name collate Latin1_General_CI_AI = a.name
left outer join
(
select 
a.name,
count (*) total
from [msl-svr267].crm_mscrm.dbo.FilteredMHR_complaints c
inner join 
[msl-svr267].crm_mscrm.dbo.FilteredAccount a
on c.mhr_complaintcustomerid = a.accountid
group by a.name) comp
on comp.name = a.name
where a.customertypecodename = 'Customer'
and a.statuscodename = 'active'
order by 1

/*
Done
-	Last purchase (vs older than 6,12,18 months)
-	Win/loss ratio at 30% or above 12, 18 or 24  (80%)
-	Modules sold but not implemented (80%)
-	Number of Open defects  (80%)
-	Average length of time call open in previous 12 months (80%)
-	Number of calls in previous 12 months (80%)
-	Since last call raised on service cloud (80%)

To Do
-	Outstanding debt

In Future
-	Number of actions closed beyond expected close date
-   actions aganist department
-   
*/