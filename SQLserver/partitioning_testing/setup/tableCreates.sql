DROP TABLE [Stage];
DROP TABLE [Target];

CREATE TABLE [Stage](
  ClientSiteID uniqueidentifier NOT NULL,
  EnvironmentName nvarchar(50) NOT NULL,
  Attr1 int)  -- no UK.  Does this make a difference?  SPEND doesn't have a UK.  PRC does
ON EnvironmentNamePs(EnvironmentName); 

CREATE TABLE [Target](
  ClientSiteID uniqueidentifier NOT NULL,
  EnvironmentName nvarchar(50) NOT NULL,
  Attr1 int)
ON EnvironmentNamePs(EnvironmentName);
