# Windows audio interfaces

Independent interop implementation; no NirSoft implementation was copied.

Documented read-only APIs:
https://learn.microsoft.com/en-us/windows/win32/api/mmdeviceapi/nn-mmdeviceapi-immdeviceenumerator
https://learn.microsoft.com/en-us/windows/win32/api/mmdeviceapi/nn-mmdeviceapi-immdevice

Undocumented ABI reference for IPolicyConfig:
https://github.com/amate/SetDefaultAudioDevice/blob/master/PolicyConfig.h
Microsoft community discussion of SetEndpointVisibility:
https://learn.microsoft.com/en-gb/answers/questions/1617393/how-to-enable-disable-audio-devices

IUnknown occupies slots 0-2. IPolicyConfig SetDefaultEndpoint occupies slot 13;
SetEndpointVisibility occupies slot 14. Calls use endpoint IDs, HRESULT checking
and release all COM references. Roles 0, 1 and 2 correspond to Console, Multimedia
and Communications. These policy methods are not a supported public Windows API.
