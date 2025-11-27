<?php
namespace Hadil\CustomFeed\Console\Command;

use Hadil\CustomFeed\Model\FeedGenerator;
use Magento\Framework\Console\Cli;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;

class Generate extends Command
{
    protected $feedGenerator;

    public function __construct(
        FeedGenerator $feedGenerator,
        string $name = null
    ) {
        $this->feedGenerator = $feedGenerator;
        parent::__construct($name);
    }

    protected function configure()
    {
        $this->setName('customfeed:generate')
            ->setDescription('Generate custom product feed');
        parent::configure();
    }

    protected function execute(InputInterface $input, OutputInterface $output)
    {
        try {
            $filePath = $this->feedGenerator->generate();
            $output->writeln('<info>Feed generated: ' . $filePath . '</info>');
            return Cli::RETURN_SUCCESS;
        } catch (\Exception $e) {
            $output->writeln('<error>Error: ' . $e->getMessage() . '</error>');
            return Cli::RETURN_FAILURE;
        }
    }
}
