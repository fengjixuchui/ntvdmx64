/* Just in case we need to be loaded as appcert DLL. 
 * Currently this is not used */
#include "ldntvdm.h"

#ifdef APPCERT_DLL
#include <ntstatus.h>


#define APPCERT_IMAGE_OK_TO_RUN   0x00000001L
#define APPCERT_CREATION_ALLOWED  0x00000002L
#define APPCERT_CREATION_DENIED   0x00000003L

__declspec(dllexport) NTSTATUS NTAPI CreateProcessNotify(
	LPCWSTR lpApplicationName,
	ULONG uNotifyReason
	)
{
#ifdef TARGET_WIN7
	UpdateSymbolCache(TRUE);
#endif
	switch (uNotifyReason)
	{
	case APPCERT_IMAGE_OK_TO_RUN:
		OutputDebugStringA("APPCERT_IMAGE_OK_TO_RUN");
		return STATUS_SUCCESS;

	case APPCERT_CREATION_ALLOWED:
		OutputDebugStringA("APPCERT_CREATION_ALLOWED");
		return STATUS_SUCCESS;

	case APPCERT_CREATION_DENIED:
		OutputDebugStringA("APPCERT_CREATION_DENIED");
		return STATUS_SUCCESS;

	default:
		OutputDebugStringA("APPCERT_UNKNOWN");
		return STATUS_SUCCESS;
	}
}

#endif