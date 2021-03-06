pragma solidity ^0.4.23;


contract ProfileRegistry {

    modifier onlySonm(){
        require(GetValidatorLevel(msg.sender) == - 1);
        _;
    }

    struct Certificate {
        address from;

        address to;

        uint attributeType;

        bytes value;
    }

    event ValidatorCreated(address indexed validator);

    event ValidatorDeleted(address indexed validator);

    event CertificateCreated(uint indexed id);

    event CertificateUpdated(uint indexed id);

    uint256 certificatesCount = 0;

    mapping(address => int8) public validators;

    mapping(uint256 => Certificate) public certificates;

    mapping(address => mapping(uint256 => bytes)) certificateValue;

    mapping(address => mapping(uint256 => uint)) certificateCount;

    constructor() public {
        validators[msg.sender] = - 1;
    }

    function AddValidator(address _validator, int8 _level) onlySonm public returns (address){
        require(_level > 0);
        require(GetValidatorLevel(_validator) == 0);
        validators[_validator] = _level;
        emit ValidatorCreated(_validator);
        return _validator;
    }

    function RemoveValidator(address _validator) onlySonm public returns (address){
        require(GetValidatorLevel(_validator) > 0);
        validators[_validator] = 0;
        emit ValidatorDeleted(_validator);
        return _validator;
    }

    function GetValidatorLevel(address _validator) view public returns (int8){
        return validators[_validator];
    }

    function CreateCertificate(address _owner, uint256 _type, bytes _value) public {
        //Check validator level
        if (_type >= 1100) {
            int8 attributeLevel = int8(_type / 100 % 10);
            require(attributeLevel <= GetValidatorLevel(msg.sender));
        } else {
            require(_owner == msg.sender);
        }

        // Check empty value
        require(keccak256(_value) != keccak256(""));

        bool isMultiple = _type / 1000 == 2;
        if (!isMultiple) {
            if (certificateCount[_owner][_type] == 0) {
                certificateValue[_owner][_type] = _value;
            } else {
                require(keccak256(GetAttributeValue(_owner, _type)) == keccak256(_value));
            }
        }

        certificateCount[_owner][_type] = certificateCount[_owner][_type] + 1;

        certificatesCount = certificatesCount + 1;
        certificates[certificatesCount] = Certificate(msg.sender, _owner, _type, _value);

        emit CertificateCreated(certificatesCount);
    }

    function RemoveCertificate(uint256 _id) public {
        Certificate memory crt = certificates[_id];

        require(crt.to == msg.sender || crt.from == msg.sender || GetValidatorLevel(msg.sender) == -1);
        require(keccak256(crt.value) != keccak256(""));

        certificateCount[crt.to][crt.attributeType] = certificateCount[crt.to][crt.attributeType] - 1;
        if (certificateCount[crt.to][crt.attributeType] == 0) {
            certificateValue[crt.to][crt.attributeType] = "";
        }
        certificates[_id].value = "";
        emit CertificateUpdated(_id);
    }

    function GetCertificate(uint256 _id) view public returns (address, address, uint256, bytes){
        return (certificates[_id].from, certificates[_id].to, certificates[_id].attributeType, certificates[_id].value);
    }

    function GetAttributeValue(address _owner, uint256 _type) view public returns (bytes){
        return certificateValue[_owner][_type];
    }

    function GetAttributeCount(address _owner, uint256 _type) view public returns (uint256){
        return certificateCount[_owner][_type];
    }

    function CheckProfileLevel(address _owner, uint _levelRequired) view public returns (bool){
        if (_levelRequired > 4) {
            return false;
        } else if (_levelRequired == 4) {
            return keccak256(GetAttributeValue(_owner, 1401)) != keccak256("");
        } else if (_levelRequired == 3) {
            return keccak256(GetAttributeValue(_owner, 1301)) != keccak256("");
        } else if (_levelRequired == 2) {
            return keccak256(GetAttributeValue(_owner, 1201)) != keccak256("");
        }
        return true;
    }
}
