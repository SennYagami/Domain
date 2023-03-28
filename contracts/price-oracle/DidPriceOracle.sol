pragma solidity >=0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "../common/StringUtils.sol";
import "./IDidPriceOracle.sol";
import "./interfaces/AggregatorInterface.sol";

// StablePriceOracle sets a price in USD, based on an oracle.
contract DidPriceOracle is IDidPriceOracle, Ownable {
    using StringUtils for *;
    //price in USD per second
    // one year = 31556952 seconds
    uint256 private constant price3Letter = 20597680029427; // 640$ per year 
    uint256 private constant price4Letter = 5070198161089; // 160$ per year
    uint256 private constant price5Letter = 158443692534; // 5$ per year

    // Oracle address
    AggregatorInterface public immutable usdOracle;

    constructor(AggregatorInterface _usdOracle) {
        usdOracle = _usdOracle;
    }

    function domainPriceInMatic(
        string calldata rootName,
        string calldata secondaryName,
        uint256 duration
    ) external view returns (IDidPriceOracle.Price memory) {
        uint256 rootLen = rootName.strlen();
        uint256 secondaryLen = rootName.strlen();
        if (secondaryLen < 3 || rootLen == 0) {
            return IDidPriceOracle.Price({base: 0, premium: 0});
        }
        uint256 basePrice;
        if (secondaryLen == 3) {
            basePrice = price3Letter * duration;
        } else if (secondaryLen == 4) {
            basePrice = price4Letter * duration;
        } else {
            basePrice = price5Letter * duration;
        }
        return IDidPriceOracle.Price({base: attoUSDToWei(basePrice), premium: 0});
    }

    function attoUSDToWei(uint256 amount) internal view returns (uint256) {
        uint256 maticPrice = uint256(usdOracle.latestAnswer());
        return (amount * 1e8) / maticPrice;
    }
}
