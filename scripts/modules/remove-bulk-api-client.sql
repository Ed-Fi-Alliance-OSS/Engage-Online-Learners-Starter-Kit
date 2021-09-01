DECLARE @ClientId int;

SELECT
	@ClientId = ApiClientId
FROM
	dbo.ApiClients
WHERE
	[name] = 'Client Bulk Loader';


DELETE FROM
	dbo.ClientAccessTokens
WHERE
	ApiClient_ApiClientId = @ClientId;


DELETE FROM
	dbo.ApiClients
WHERE ApiClientId = @ClientId;
