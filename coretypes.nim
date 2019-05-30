
type
    TypeCode* = int32
    BigTime* = int64
    TeamId* = distinct pointer

const
    INFINITE_TIMEOUT* = high(BigTime)

    MSG_SPECIFIER*: uint32 = 1

    # [[[cog
    # cons = """ANY_TYPE CHAR_TYPE INT8_TYPE INT16_TYPE INT32_TYPE INT64_TYPE
    # UINT8_TYPE UINT16_TYPE UINT32_TYPE UINT64_TYPE FLOAT_TYPE
    # DOUBLE_TYPE BOOL_TYPE OFF_T_TYPE SIZE_T_TYPE SSIZE_T_TYPE
    # POINTER_TYPE OBJECT_TYPE MESSAGE_TYPE MESSENGER_TYPE POINT_TYPE
    # RECT_TYPE PATH_TYPE REF_TYPE RGB_COLOR_TYPE PATTERN_TYPE
    # STRING_TYPE MONOCHROME_1_BIT_TYPE GRAYSCALE_8_BIT_TYPE
    # COLOR_8_BIT_TYPE RGB_32_BIT_TYPE TIME_TYPE MEDIA_PARAMETER_TYPE
    # MEDIA_PARAMETER_WEB_TYPE MEDIA_PARAMETER_GROUP_TYPE RAW_TYPE
    # MIME_TYPE"""
    # for i, c in enumerate(cons.replace('\n', ' ').split(' ')):
    #   cog.outl('{}*: TypeCode = {}'.format(c, i))
    # ]]]
    ANY_TYPE*: TypeCode = 0
    CHAR_TYPE*: TypeCode = 1
    INT8_TYPE*: TypeCode = 2
    INT16_TYPE*: TypeCode = 3
    INT32_TYPE*: TypeCode = 4
    INT64_TYPE*: TypeCode = 5
    UINT8_TYPE*: TypeCode = 6
    UINT16_TYPE*: TypeCode = 7
    UINT32_TYPE*: TypeCode = 8
    UINT64_TYPE*: TypeCode = 9
    FLOAT_TYPE*: TypeCode = 10
    DOUBLE_TYPE*: TypeCode = 11
    BOOL_TYPE*: TypeCode = 12
    OFF_T_TYPE*: TypeCode = 13
    SIZE_T_TYPE*: TypeCode = 14
    SSIZE_T_TYPE*: TypeCode = 15
    POINTER_TYPE*: TypeCode = 16
    OBJECT_TYPE*: TypeCode = 17
    MESSAGE_TYPE*: TypeCode = 18
    MESSENGER_TYPE*: TypeCode = 19
    POINT_TYPE*: TypeCode = 20
    RECT_TYPE*: TypeCode = 21
    PATH_TYPE*: TypeCode = 22
    REF_TYPE*: TypeCode = 23
    RGB_COLOR_TYPE*: TypeCode = 24
    PATTERN_TYPE*: TypeCode = 25
    STRING_TYPE*: TypeCode = 26
    MONOCHROME_1_BIT_TYPE*: TypeCode = 27
    GRAYSCALE_8_BIT_TYPE*: TypeCode = 28
    COLOR_8_BIT_TYPE*: TypeCode = 29
    RGB_32_BIT_TYPE*: TypeCode = 30
    TIME_TYPE*: TypeCode = 31
    MEDIA_PARAMETER_TYPE*: TypeCode = 32
    MEDIA_PARAMETER_WEB_TYPE*: TypeCode = 33
    MEDIA_PARAMETER_GROUP_TYPE*: TypeCode = 34
    RAW_TYPE*: TypeCode = 35
    MIME_TYPE*: TypeCode = 36
    # [[[end]]]
