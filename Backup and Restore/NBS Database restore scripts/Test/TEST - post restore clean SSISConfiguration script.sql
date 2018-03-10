

SELECT * FROM dbo.REF_SSISConfiguration where ConfiguredValue like '%e1srv%'
update dbo.REF_SSISConfiguration set ConfiguredValue = 'aqadbs009' where ConfiguredValue like '%e1srv%'
SELECT * FROM dbo.REF_SSISConfiguration where ConfiguredValue like '%aqadbs009%'

SELECT * FROM dbo.REF_SSISConfiguration where ConfiguredValue like '%mcdbsupport2%'
update dbo.REF_SSISConfiguration set ConfiguredValue = 'nkent@asa.org,lconnors@asa.org' where ConfiguredValue like '%mcdbsupport2%'
SELECT * FROM dbo.REF_SSISConfiguration where ConfiguredValue like '%nkent@asa.org,lconnors@asa.org%'

SELECT * FROM dbo.REF_SSISConfiguration where ConfiguredValue like '%AOPSDBSCLSTR02\MCDB%'
update dbo.REF_SSISConfiguration set ConfiguredValue = 'AQADBSCLSTR02\MCDB' where ConfiguredValue like '%AOPSDBSCLSTR02\MCDB%'
SELECT * FROM dbo.REF_SSISConfiguration where ConfiguredValue like '%AQADBSCLSTR02\MCDB%'

