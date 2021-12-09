DELETE FROM
	dbo.ClientAccessTokens
WHERE EXISTS (
	SELECT
		1
	FROM
		dbo.ApiClients
	WHERE
		[name] = 'Starter Kit Bulk Loader'
	AND
		ClientAccessTokens.ApiClient_ApiClientId = ApiClients.ApiClientId
)


DELETE FROM
    dbo.ApiClientApplicationEducationOrganizations
WHERE EXISTS (
	SELECT
		1
	FROM
		dbo.ApiClients
	WHERE
		[name] = 'Starter Kit Bulk Loader'
	AND
		ApiClientApplicationEducationOrganizations.ApiClient_ApiClientId = ApiClients.ApiClientId
)


DELETE FROM
	dbo.ApiClients
WHERE
	[name] = 'Starter Kit Bulk Loader';


DELETE FROM
	dbo.ApplicationEducationOrganizations
WHERE EXISTS (
	SELECT
		1
	FROM
		dbo.Applications
	WHERE
		Applications.ApplicationName = 'Starter Kit Bulk Loader'
	AND
		Applications.ApplicationId = ApplicationEducationOrganizations.Application_ApplicationId
)


DELETE FROM
	dbo.Applications
WHERE
	ApplicationName = 'Starter Kit Bulk Loader';


DELETE FROM
	dbo.VendorNamespacePrefixes
WHERE EXISTS (
	SELECT
		1
	FROM
		dbo.Vendors
	WHERE
		VendorName = 'Starter Kit Vendor'
	AND
		VendorNamespacePrefixes.Vendor_VendorId = Vendors.VendorId
);


DELETE FROM
	dbo.Vendors
WHERE
	VendorName = 'Starter Kit Vendor';
