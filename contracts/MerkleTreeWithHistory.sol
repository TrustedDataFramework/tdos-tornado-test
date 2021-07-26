// https://tornado.cash
/*
* d888888P                                           dP              a88888b.                   dP
*    88                                              88             d8'   `88                   88
*    88    .d8888b. 88d888b. 88d888b. .d8888b. .d888b88 .d8888b.    88        .d8888b. .d8888b. 88d888b.
*    88    88'  `88 88'  `88 88'  `88 88'  `88 88'  `88 88'  `88    88        88'  `88 Y8ooooo. 88'  `88
*    88    88.  .88 88       88    88 88.  .88 88.  .88 88.  .88 dP Y8.   .88 88.  .88       88 88    88
*    dP    `88888P' dP       dP    dP `88888P8 `88888P8 `88888P' 88  Y88888P' `88888P8 `88888P' dP    dP
* ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
*/

pragma solidity 0.5.17;

library Hasher {
  function MiMCSponge(uint256 in_xL, uint256 in_xR) public pure returns (uint256 xL, uint256 xR);
}

interface Logger {
  function log(string calldata s) pure external;
  function log(address s) pure external;
  function log(uint256 s) pure external;
}

contract MerkleTreeWithHistory {
  uint256 public constant FIELD_SIZE = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
  uint256 public constant ZERO_VALUE = 21663839004416932945382355908790599225266501822907911457504978515578255421292; // = keccak256("tornado") % FIELD_SIZE

  uint32 public levels;

  // the following variables are made public for easier testing and debugging and
  // are not supposed to be accessed in regular code
  bytes32[] public filledSubtrees;
  bytes32[] public zeros;
  uint32 public currentRootIndex = 0;
  uint32 public nextIndex = 0;
  uint32 public constant ROOT_HISTORY_SIZE = 100;
  bytes32[ROOT_HISTORY_SIZE] public roots;
  Logger logger = Logger(0x0000000000000000000000000000000000000001);

  constructor(uint32 _treeLevels) public {
    logger.log("MerkleTreeWithHistory into");
    require(_treeLevels > 0, "_treeLevels should be greater than zero");
    require(_treeLevels < 32, "_treeLevels should be less than 32");
    levels = _treeLevels;
    logger.log("MerkleTreeWithHistory into 000");
    bytes32 currentZero = bytes32(ZERO_VALUE);
    zeros.push(currentZero);
    filledSubtrees.push(currentZero);
    logger.log("MerkleTreeWithHistory into 111");
    for (uint32 i = 1; i < levels; i++) {
      logger.log("MerkleTreeWithHistory begin ");
      currentZero = hashLeftRight(currentZero, currentZero);
      logger.log("MerkleTreeWithHistory end ");
      zeros.push(currentZero);
      filledSubtrees.push(currentZero);
    }
    logger.log("MerkleTreeWithHistory into 222");
    roots[0] = hashLeftRight(currentZero, currentZero);
    logger.log("MerkleTreeWithHistory exit");
  }

  /**
    @dev Hash 2 tree leaves, returns MiMC(_left, _right)
  */
  function hashLeftRight(bytes32 _left, bytes32 _right) public view returns (bytes32) {
    logger.log("hashLeftRight begin  000");
    require(uint256(_left) < FIELD_SIZE, "_left should be inside the field");
    require(uint256(_right) < FIELD_SIZE, "_right should be inside the field");
    uint256 R = uint256(_left);
    uint256 C = 0;
    logger.log("hashLeftRight begin");
    logger.log(R);
    logger.log(C);
    (R, C) = Hasher.MiMCSponge(R, C);
    logger.log("hashLeftRight begin 111");
    R = addmod(R, uint256(_right), FIELD_SIZE);
    logger.log("hashLeftRight begin 222");
    (R, C) = Hasher.MiMCSponge(R, C);
    logger.log("hashLeftRight exit");
    return bytes32(R);
  }

  function _insert(bytes32 _leaf) internal returns(uint32 index) {
    uint32 currentIndex = nextIndex;
    require(currentIndex != uint32(2)**levels, "Merkle tree is full. No more leafs can be added");
    nextIndex += 1;
    bytes32 currentLevelHash = _leaf;
    bytes32 left;
    bytes32 right;

    for (uint32 i = 0; i < levels; i++) {
      if (currentIndex % 2 == 0) {
        left = currentLevelHash;
        right = zeros[i];

        filledSubtrees[i] = currentLevelHash;
      } else {
        left = filledSubtrees[i];
        right = currentLevelHash;
      }

      currentLevelHash = hashLeftRight(left, right);

      currentIndex /= 2;
    }

    currentRootIndex = (currentRootIndex + 1) % ROOT_HISTORY_SIZE;
    roots[currentRootIndex] = currentLevelHash;
    return nextIndex - 1;
  }

  /**
    @dev Whether the root is present in the root history
  */
  function isKnownRoot(bytes32 _root) public view returns(bool) {
    if (_root == 0) {
      return false;
    }
    uint32 i = currentRootIndex;
    do {
      if (_root == roots[i]) {
        return true;
      }
      if (i == 0) {
        i = ROOT_HISTORY_SIZE;
      }
      i--;
    } while (i != currentRootIndex);
    return false;
  }

  /**
    @dev Returns the last root
  */
  function getLastRoot() public view returns(bytes32) {
    return roots[currentRootIndex];
  }
}
