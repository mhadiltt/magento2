<?php
namespace Hadil\CustomFeed\Model;

use Magento\Catalog\Model\ResourceModel\Product\CollectionFactory;
use Magento\Framework\Filesystem\DirectoryList;
use Magento\Framework\Filesystem\Io\File;
use Psr\Log\LoggerInterface;

class FeedGenerator
{
    protected $productCollectionFactory;
    protected $directoryList;
    protected $file;
    protected $logger;

    public function __construct(
        CollectionFactory $productCollectionFactory,
        DirectoryList $directoryList,
        File $file,
        LoggerInterface $logger
    ) {
        $this->productCollectionFactory = $productCollectionFactory;
        $this->directoryList = $directoryList;
        $this->file = $file;
        $this->logger = $logger;
    }

    public function generate()
    {
        try {
            // 1. Get products
            $collection = $this->productCollectionFactory->create();
            $collection->addAttributeToSelect(['sku', 'name', 'price', 'status', 'visibility']);
            $collection->addAttributeToFilter('status', 1); // enabled products

            // 2. Prepare file path
            $varDir = $this->directoryList->getPath(DirectoryList::VAR_DIR);
            $exportDir = $varDir . '/export';
            $filePath = $exportDir . '/custom_feed.csv';

            if (!$this->file->fileExists($exportDir, false)) {
                $this->file->mkdir($exportDir, 0755);
            }

            // 3. Open file & write header
            $handle = fopen($filePath, 'w');
            fputcsv($handle, ['sku', 'name', 'price', 'status', 'visibility']);

            // 4. Write data
            foreach ($collection as $product) {
                fputcsv($handle, [
                    $product->getSku(),
                    $product->getName(),
                    $product->getPrice(),
                    $product->getStatus(),
                    $product->getVisibility()
                ]);
            }

            fclose($handle);

            $this->logger->info('Custom feed generated: ' . $filePath);
            return $filePath;
        } catch (\Exception $e) {
            $this->logger->error('Custom feed generation error: ' . $e->getMessage());
            throw $e;
        }
    }
}
